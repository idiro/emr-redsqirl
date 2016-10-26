#!/bin/bash
set -e

##################################################
if [[ -z "$AWSKEYPATH" ]]; then
    echo "The environment variable \"AWSKEYPATH\" has to be set"
    exit 1;
fi
if [[ -z "$AWSKEYNAME" ]]; then
    echo "The environment variable \"AWSKEYNAME\" has to be set"
    exit 1;
fi
##################################################

function create_body
{

    MESSAGE_COM1="Dear ${u_fullname},\n\n"
    MESSAGE_COM1=$MESSAGE_COM1"You have been given access to a RedSqirl cluster through AWS EMR." 
    MESSAGE_COM1=$MESSAGE_COM1"The master DNS is ${MASTERPUBLICDNS}.\n\n"
    MESSAGE_COM1=$MESSAGE_COM1"Documentation on AWS EMR:\n"
    MESSAGE_COM1=$MESSAGE_COM1"http://aws.amazon.com/activate\n"
    MESSAGE_COM1=$MESSAGE_COM1"http://aws.amazon.com/elasticmapreduce\n"
    MESSAGE_COM1=$MESSAGE_COM1"\n"

    MESSAGE_COM1=$MESSAGE_COM1"Username: ${u}\n"
    MESSAGE_COM1=$MESSAGE_COM1"Password: ${u_password}\n\n"

    MESSAGE_COM1=$MESSAGE_COM1"You can ssh directly into the master, however in order to make the master server websites"
    MESSAGE_COM1=$MESSAGE_COM1" available you need to create an ssh tunnel and configure your browser. "

    MESSAGE_COM1=$MESSAGE_COM1"Please read the following idiro guide.\n"
    MESSAGE_COM1=$MESSAGE_COM1"http://banville.local.net/wiki/index.php/Guide:_Connect_through_a_browser_to_AWS_EMR\n"
    MESSAGE_COM1=$MESSAGE_COM1"If you don't have access to it, use amazon guide (please read Part 1 and 2). However you can ignore the part about ssh key as you have a password.\n"
    MESSAGE_COM1=$MESSAGE_COM1"http://docs.aws.amazon.com/ElasticMapReduce/latest/DeveloperGuide/emr-ssh-tunnel.html\n\n"
    MESSAGE_COM1=$MESSAGE_COM1"The command line for creating the tunnel on linux is below." 
    MESSAGE_COM1=$MESSAGE_COM1" Don't forget to adapt the port \"8157\" to your need.\n"
    MESSAGE_COM1=$MESSAGE_COM1"ssh -CND 8157 ${u}@${MASTERPUBLICDNS}\n\n"

    MESSAGE_COM1=$MESSAGE_COM1"For security reasons the cluster is restricted from outside access. If you cannot reach the host please provide the administrator with your IP address, available from:\n"
    MESSAGE_COM1=$MESSAGE_COM1"http://whatismyipaddress.com/\n\n"

    MESSAGE_COM1=$MESSAGE_COM1"If you want to change your password, you will need to ssh into your own account, see above, and set your password (\"passwd\" command)\n\n"

    MESSAGE_RESIZER_USER="Your user has resize privilege, it means you can request more computational resources if needed. "
    MESSAGE_RESIZER_USER=$MESSAGE_RESIZER_USER"In order to resize, you need to ssh master and execute \"/opt/resizer/bin/resize\". Please find an example below.\n" 
    MESSAGE_RESIZER_USER=$MESSAGE_RESIZER_USER"/opt/resizer/bin/resize 2 1:00\n"
    MESSAGE_RESIZER_USER=$MESSAGE_RESIZER_USER"The command takes two arguments.  The number of additional server (between 1 and 5) and the duration you need them up from 1 minute (0:01) to 9 hours 59 minutes (9:59). Note that resizing may takes several minutes before the resources are actually online.\n\n"

    MESSAGE_COM_END="Please note that if too many job are kicked off at once, the cluster will automatically adjust the number of processing nodes. This resize may take some time though.\n\n"

    MESSAGE_COM_END=$MESSAGE_COM_END"The cluster settings are below, more information about the instance types on http://aws.amazon.com/ec2/instance-types.\n"
    MESSAGE_COM_END=$MESSAGE_COM_END"MASTER: 1, ${MASTER_TYPE}\n"
    MESSAGE_COM_END=$MESSAGE_COM_END"CORE: ${CORE_COUNT}, ${CORE_TYPE}\n"
    MESSAGE_COM_END=$MESSAGE_COM_END"TASK: Resizable, ${TASK_TYPE}\n\n"
    MESSAGE_COM_END=$MESSAGE_COM_END"For any questions please contact the administrator ${admin_email}.\n\n"

    MESSAGE_COM_END=$MESSAGE_COM_END"Useful links once the ssh tunnel is setup:\n"
    MESSAGE_COM_END=$MESSAGE_COM_END"RedSqirl: http://${MASTERPUBLICDNS}:8842/redsqirl\n"
    MESSAGE_COM_END=$MESSAGE_COM_END"Logs: http://${MASTERPUBLICDNS}:19888/jobhistory/logs\n"
    MESSAGE_COM_END=$MESSAGE_COM_END"ResourceManager: http://${MASTERPUBLICDNS}:9026\n"
    MESSAGE_COM_END=$MESSAGE_COM_END"Ganglia: http://${MASTERPUBLICDNS}/ganglia\n"
    MESSAGE_COM_END=$MESSAGE_COM_END"Namenode: http://${MASTERPUBLICDNS}:9101\n"
    MESSAGE_COM_END=$MESSAGE_COM_END"Oozie: http://${MASTERPUBLICDNS}:11000\n"
    MESSAGE_COM_END=$MESSAGE_COM_END"\n"


    MESSAGE_COM_END=$MESSAGE_COM_END"Regards,\n"
    MESSAGE_REG_USER=${MESSAGE_COM1}${MESSAGE_COM_END}
    MESSAGE_RESIZER_USER=${MESSAGE_COM1}${MESSAGE_RESIZER_USER}${MESSAGE_COM_END}
}

SCRIPT_LOCATION=${BASH_SOURCE[0]}
SCRIPT_PATH="$(cd $(dirname "${SCRIPT_LOCATION}"); pwd -P)/$(basename "${SCRIPT_LOCATION}")"
SCRIPT_PATH="${SCRIPT_PATH%/*}"

HOME_PROJECT=$(dirname ${SCRIPT_PATH})

CONF_FILE=${HOME_PROJECT}/conf/cluster.properties
source ${CONF_FILE} 2> /dev/null

CLUSTER_NAME=$1
USERS=$2
RESIZER_MEMBERS=$3

#echo "Call send email with: $CLUSTER_NAME $USERS $RESIZER_MEMBERS"
CLUSTER_FOLDER=${HOME_PROJECT}/clusters/${CLUSTER_NAME}

MASTERPUBLICDNS="myawsserver";
if [[ -z "$CLUSTER_NAME" || ! -d ${CLUSTER_FOLDER} ]]; then
    echo "The cluster ${CLUSTER_NAME} does not exist"
    exit 1;
fi

PASSWORD_FILE=${CLUSTER_FOLDER}/users/password
JOBFLOWID=`cat ${CLUSTER_FOLDER}/jobflowid`
MASTERPUBLICDNS=`aws emr describe-cluster --cluster-id $JOBFLOWID  | grep "MasterPublicDnsName" | cut -d "\"" -f 4`;
SUBJECT="Connection details for AWS/EMR cluster: ${CLUSTER_NAME}"

IFS=":"
for u in $USERS; do
    echo User $u
    u_email_var=`echo ${u}_email`
    #echo Email var $u_email_var
    u_email=`cat ${CONF_FILE} | grep ${u_email_var} | cut -d'=' -f 2 | tr -d '"'`
    #echo Email $u_email
    u_fullname_var=`echo ${u}_fullname`
    #echo Fullname var $u_fullname_var
    u_fullname=`cat ${CONF_FILE} | grep ${u_fullname_var} | cut -d'=' -f 2 | tr -d '"'`
    #echo Fullname $u_fullname
    #echo ${PASSWORD_FILE}
    u_password=`cat ${PASSWORD_FILE} | grep ${u}` ||true
    #echo Password $u_password
    if [[ -n "${u_password}" ]]; then
	u_password=${u_password#*=}
    else
	echo "WARN: no password found for ${u}"
    fi

    if [ -z "${u_fullname}" ]; then
	u_fullname="user "$u
    fi
    if [ -n "${u_email}" ]; then
	re="(^|:)"$u"($|:)"
	create_body
	#echo "#################################"
	#echo "Resize email"
	#echo -e ${MESSAGE_RESIZER_USER}
	#echo "#################################"
	#echo "#################################"
	#echo Regular email
	#echo -e ${MESSAGE_REG_USER}
	#echo "#################################"
	if [[ $RESIZER_MEMBERS  =~ $re ]]; then
	    #echo -e ${MESSAGE_RESIZER_USER}
	    echo -e "$MESSAGE_RESIZER_USER" | mail -s "$SUBJECT" "$u_email"
	else
	    #echo -e ${MESSAGE_REG_USER}
	    echo -e "$MESSAGE_REG_USER" | mail -s "$SUBJECT" "$u_email"
	fi
        #echo `cat ${CONF_FILE} | grep ${u_email_var}` >> ${CLUSTER_FOLDER}/conf/cluster.properties
        #echo `cat ${CONF_FILE} | grep ${u_fullname_var}` >> ${CLUSTER_FOLDER}/conf/cluster.properties
    else
	echo "No email details given for user $u"
    fi
done

