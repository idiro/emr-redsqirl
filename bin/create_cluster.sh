#!/bin/bash
set -e

#Upload a tool and install it
function uploadAndInstall {
	_DIRECTORY_FILE=$1
	_INSTALLATION_FILE=$2
	_DIRECTORY_BIN=$3
	_INSTALL_SCRIPT=$4
	aws emr put --cluster-id $JOBFLOWID --key-pair-file $AWSKEYPATH --src "${_DIRECTORY_FILE}/${_INSTALLATION_FILE}"
	aws emr put --cluster-id $JOBFLOWID --key-pair-file $AWSKEYPATH --src "${_DIRECTORY_BIN}/${_INSTALL_SCRIPT}" > /dev/null
	aws emr ssh --cluster-id $JOBFLOWID --key-pair-file $AWSKEYPATH --command "chmod +x ${_INSTALL_SCRIPT}" > /dev/null
	aws emr ssh --cluster-id $JOBFLOWID --key-pair-file $AWSKEYPATH --command "./${_INSTALL_SCRIPT}" > /dev/null
	aws emr ssh --cluster-id $JOBFLOWID --key-pair-file $AWSKEYPATH --command "rm ${_INSTALL_SCRIPT}" > /dev/null
}

function listInstanceTypes {
    echo '"m1.medium" "m1.large" "m1.xlarge" "m3.xlarge" "m3.2xlarge" "i2.xlarge"  "i2.2xlarge" "i2.4xlarge" "i2.8xlarge" "hs1.8xlarge" "r3.xlarge" "r3.2xlarge" "r3.4xlarge" "r3.8xlarge" "c3.xlarge"  "c3.2xlarge" "c3.4xlarge" "c3.8xlarge"'
}

function isInstanceType {
    echo `containsElement $1 \
	    "m1.medium" "m1.large" "m1.xlarge" \
	    "m3.xlarge" "m3.2xlarge" \
	    "i2.xlarge"  "i2.2xlarge" "i2.4xlarge" "i2.8xlarge" "hs1.8xlarge" \
	    "r3.xlarge" "r3.2xlarge" "r3.4xlarge" "r3.8xlarge" \
	    "c3.xlarge"  "c3.2xlarge" "c3.4xlarge" "c3.8xlarge"`
}

function containsElement {
    local e
    for e in "${@:2}"; do 
	if [[ "$e" == "$1" ]]; then
	    echo 0
	    exit
	fi
    done
    echo 1
}

function help {
    echo -e "create_cluster.sh -n clusterName [-f CONF_FILE] [-s step] [-m MASTER_INSTANCE] [-c CORE_INSTANCE] [-t TASK_INSTANCE] [-N NUMBER_OF_CORE] [-h]"
    echo -e " "
    echo -e "-n Name of the cluster"
    echo -e "-s starting step, default 0 "
    echo -e "\t0 create cluster"
    echo -e "\t1 admin notification setup"
    echo -e "\t2 upload user passwords"
    echo -e "\t3 send emails"
    echo -e "\t4 display cluster details"
    echo -e "-m Master instance type, default $MASTER_TYPE"
    echo -e "-c Core instance type, default $CORE_TYPE"
    echo -e "-t Task instance type, default $TASK_TYPE"
    echo -e "-N Number of Task instance type, default $CORE_COUNT"
    echo -e "-f The conf folder, default ${CONF_FOLDER}"
    echo -e "-h Display this help"
    echo -e " "
    echo -e "List of EMR instances accepted:"
    listInstanceTypes
}

##################################################
################# Requirement ####################
if [[ -z "$AWSKEYPATH" ]]; then
    echo "The environment variable \"AWSKEYPATH\" has to be set"
    exit 1;
fi
if [[ -z "$AWSKEYNAME" ]]; then
    echo "The environment variable \"AWSKEYNAME\" has to be set"
    exit 1;
fi

##################################################
############## Init Parameters ###################
SCRIPT_LOCATION=${BASH_SOURCE[0]}
SCRIPT_PATH="$(cd $(dirname "${SCRIPT_LOCATION}"); pwd -P)/$(basename "${SCRIPT_LOCATION}")"
SCRIPT_PATH="${SCRIPT_PATH%/*}"
HOME_PROJECT=${SCRIPT_PATH}/..
CONF_FOLDER=${HOME_PROJECT}/conf

STEP=0;
while getopts "n:s:m:c:t:N:h" opt; do
    case $opt in
	n)
	    CLUSTER_NAME=$OPTARG
	    ;;
	s)
	    STEP=$OPTARG
	    ;;
	m)
	    MASTER_TYPE=$OPTARG
	    ;;
	c)
	    CORE_TYPE=$OPTARG
	    ;;
	t)
	    TASK_TYPE=$OPTARG
	    ;;
	N)
	    CORE_COUNT=$OPTARG
	    ;;
    f)
        CONF_FOLDER=$OPTARG
        ;;
	h)
	    help
	    exit 0;
	    ;;
    esac
done
CONF_FILE=${CONF_FOLDER}/cluster.properties
source ${CONF_FILE} 2> /dev/null
source ${HOME_PROJECT}/conf/s3.properties 2> /dev/null

CLUSTER_FOLDER=${HOME_PROJECT}/clusters/${CLUSTER_NAME}

#Check step number
reNb='^[0-9]+$'
if ! [[ "$STEP" =~ $reNb ]] ; then
    echo "error: Step $STEP not a number" >&2; 
    exit 1
fi

#Check inputs
if [[ "${STEP}" == 0 ]]; then
    #Check cluster name
    if [[ -z "$CLUSTER_NAME" || -d ${HOME_PROJECT}/clusters/${CLUSTER_NAME} ]]; then
	echo Script takes the CLUSTER_NAME as argument
	echo "Impossible to create the cluster ${CLUSTER_NAME}"
	exit 1;
    fi
    #Check instance types
    if [[ `isInstanceType $MASTER_TYPE` == 1 ]]; then
	echo Master type $MASTER_TYPE unknown
	exit 1;
    fi
    if [[ `isInstanceType $CORE_TYPE` == 1 ]]; then
	echo Core type $CORE_TYPE unknown
	exit 1;
    fi
    if [[ `isInstanceType $TASK_TYPE` == 1 ]]; then
	echo Task type $TASK_TYPE unknown
	exit 1;
    fi
    if ! [[ "$CORE_COUNT" =~ $reNb ]] ; then
	echo "error: Number of core $CORE_COUNT not a number" >&2; 
	exit 1
    fi

elif [[ "${STEP}" > 0 ]]; then
    if [[ -z "$CLUSTER_NAME" || ! -d ${HOME_PROJECT}/clusters/${CLUSTER_NAME} ]]; then
	echo Script takes the CLUSTER_NAME as argument
	echo "The directory ${CLUSTER_NAME} does not exist"
	exit 1;
    fi
fi

##################################################
############## Read user input ###################
if [[ "${STEP}" -le 1 ]]; then
    INSTALL_RS="y"
    INSTALL_SN="N"
    #echo Would you like to install redsqirl? [y/N]
    #read INSTALL_RS
    #echo Would you like to install sqirl-nutcracker? [y/N]
    #read INSTALL_SN
fi

echo Would you like to install the default users? [y/N]
read DEFAULT_USER 

if [[ "${DEFAULT_USER}" == 'y' || "${DEFAULT_USER}" == 'Y' ]]; then
   echo "Default users: ${extra_users}" 
else
    echo "Please specify the users to create in a list delimited by: "
    read extra_users
fi

echo Would you like to copy some data from s3? [y/N]
read DATA_COPY
if [[ "${DATA_COPY}" == 'y' || "${DATA_COPY}" == 'Y' ]]; then
    DATA_SET=`aws s3 ls ${BOOTSTRAP_DATA} | awk -F " " '{print $NF}' \
	| tr -d '/' | sed ':a;N;$!ba;s/\n/:/g'`
    echo "DATA set available: "$DATA_SET
    echo "What are the data set you want to download, ':' delimited"
    read DATA_UPLOAD
fi
##################################################
##################################################
############### Start cluster ####################
if [[ "${STEP}" == 0 ]]; then
    mkdir -p ${CLUSTER_FOLDER}
    mkdir -p ${CLUSTER_FOLDER}/conf
    cp -r ${HOME_PROJECT}/local/* ${CLUSTER_FOLDER}/ 
    cp ${CONF_FILE} ${CLUSTER_FOLDER}/conf
    chmod 500 ${CLUSTER_FOLDER}/bin/*
    echo "cluster_users=${extra_users}" >> ${CLUSTER_FOLDER}/conf/cluster.properties

    BOOTSTRAP_USERS="${BOOTSTRAP_SCRIPT}/create_users.sh"
    BOOTSTRAP_SSH="${BOOTSTRAP_SCRIPT}/setup_ssh.sh"
    BOOTSTRAP_HAMA="${BOOTSTRAP_SCRIPT}/install-hama.sh"
    BOOTSTRAP_MRQL="${BOOTSTRAP_SCRIPT}/install-mrql.sh"
    BOOTSTRAP_SHINY="${BOOTSTRAP_SCRIPT}/install-shiny.sh"
    BOOTSTRAP_REDSQIRL="${BOOTSTRAP_SCRIPT}/install-redsqirl.sh"

    STEP_CREATEHOME="${BOOTSTRAP_SCRIPT}/create_hadoophomes.sh"
    STEP_INITMRQL="${BOOTSTRAP_SCRIPT}/init-mrql.sh"
    STEP_INITDATA="${BOOTSTRAP_SCRIPT}/init-data.sh"

    aws emr create-cluster \
        --release-label emr-5.0.0 \
        --name "${CLUSTER_NAME}" \
        --applications Name=Hive Name=Oozie Name=Pig Name=Tez \
        --visible-to-all-users --use-default-role \
        --instance-groups InstanceGroupType=MASTER,InstanceCount=1,InstanceType=${MASTER_TYPE} InstanceGroupType=CORE,InstanceCount=${CORE_COUNT},InstanceType=${CORE_TYPE} \
        --ec2-attributes KeyName=$AWSKEYNAME \
        --bootstrap-action Path=${BOOTSTRAP_REDSQIRL},Args=["${extra_users}"],Name="Install Red Sqirl" Path=${BOOTSTRAP_USERS},Name="Create Users",Args=["${CLUSTER_NAME}","${extra_users}","${resizer_group}",""] Path=${BOOTSTRAP_SSH},Name="Reconfigure SSH" Path=${BOOTSTRAP_SHINY},Name="Install Shiny" \
        --steps Type=CUSTOM_JAR,Name="HDFS Homes",ActionOnFailure=CONTINUE,Jar="s3://elasticmapreduce/libs/script-runner/script-runner.jar",Args=["${STEP_CREATEHOME}","${extra_users}"] Type=CUSTOM_JAR,Name="Data Download",ActionOnFailure=CONTINUE,Jar="s3://elasticmapreduce/libs/script-runner/script-runner.jar",Args=["${STEP_INITDATA}","${extra_users}","${DATA_UPLOAD}"] \
	| grep ClusterId | cut -d "\"" -f 4 > ${CLUSTER_FOLDER}/jobflowid

    chmod 400 ${CLUSTER_FOLDER}/jobflowid
fi

##################################################
############## Save cluster id ###################
JOBFLOWID=`cat ${CLUSTER_FOLDER}/jobflowid`
if [[ "${STEP}" == 0 ]]; then
    while :
    do 
	STATE=`aws emr describe-cluster --cluster-id $JOBFLOWID | grep \"State\" | cut -d "\"" -f 4 | head -1`
        if [[ "$STATE" == "WAITING" ]]; then
	    break
	else
	    echo `date`" "$STATE
	    sleep 26
	fi
    done
    MASTERPUBLICDNS=`aws emr describe-cluster --cluster-id $JOBFLOWID  | grep "MasterPublicDnsName" | cut -d "\"" -f 4`;
    ssh -o ServerAliveInterval=10 -o StrictHostKeyChecking=no -i $AWSKEYPATH -t ec2-user@${MASTERPUBLICDNS} sudo cp /home/ec2-user/.ssh/authorized_keys /home/hadoop/.ssh/
    ssh -o ServerAliveInterval=10 -o StrictHostKeyChecking=no -i $AWSKEYPATH -t ec2-user@${MASTERPUBLICDNS} sudo chown hadoop:hadoop  /home/hadoop/.ssh/authorized_keys
else
    MASTERPUBLICDNS=`aws emr describe-cluster --cluster-id $JOBFLOWID  | grep "MasterPublicDnsName" | cut -d "\"" -f 4`;
fi


##################################################
############## Add TASK group ####################
if [[ "${STEP}" == 0 ]]; then
    aws emr add-instance-groups --cluster-id  $JOBFLOWID --instance-groups InstanceCount=0,InstanceGroupType=TASK,InstanceType=${TASK_TYPE}
fi

##################################################
######### Send Admin email notification ##########
if [[ "${STEP}" -le 1 ]]; then
    echo Setup Email Alert
    ${SCRIPT_PATH}/setup_email_notification.sh ${CLUSTER_NAME} ${admin_email}
fi

##################################################
############# Get the user details  ##############
if [[ "${STEP}" -le 2 ]]; then
    echo Gather users keys
    ${SCRIPT_PATH}/get_users.sh ${CLUSTER_NAME}
fi

##################################################
####### Send personal email with details  ########
if [[ "${STEP}" -le 3 && -n "$extra_users" ]]; then
    echo Send Email to users
	${SCRIPT_PATH}/display_details.sh ${CLUSTER_NAME}
	echo Would you like to send emails to the users? [Y/n]
	read SEND_EMAIL
	if [[ "${SEND_EMAIL}" != 'n' && "${SEND_EMAIL}" != 'N' ]]; then
	    ${SCRIPT_PATH}/send_email_to_user_with_key.sh ${CLUSTER_NAME} ${extra_users} ${resizer_group} 
	fi
fi

##################################################
## Display cluster details and useful command  ###
if [[ "${STEP}" -le 4 ]]; then
    ${SCRIPT_PATH}/display_details.sh ${CLUSTER_NAME}
fi
