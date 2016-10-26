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
    MESSAGE_COM1=$MESSAGE_COM1"The cluster ${CLUSTER_NAME} (${MASTERPUBLICDNS}) has been shutdown.\n\n"
    MESSAGE_COM1=$MESSAGE_COM1"Regards,\n"
    MESSAGE_USER=${MESSAGE_COM1}
}

SCRIPT_LOCATION=${BASH_SOURCE[0]}
SCRIPT_PATH="$(cd $(dirname "${SCRIPT_LOCATION}"); pwd -P)/$(basename "${SCRIPT_LOCATION}")"
SCRIPT_PATH="${SCRIPT_PATH%/*}"

HOME_CLUSTER=$(dirname ${SCRIPT_PATH})

CONF_FILE=${HOME_CLUSTER}/conf/cluster.properties
source ${CONF_FILE} 2> /dev/null

CLUSTER_NAME=$(basename ${HOME_CLUSTER})
JOBFLOWID=`cat ${HOME_CLUSTER}/jobflowid`
MASTERPUBLICDNS=`aws emr describe-cluster --cluster-id $JOBFLOWID  | grep "MasterPublicDnsName" | cut -d "\"" -f 4`;
USERS=${cluster_users}

SUBJECT="Shut down of the AWS/EMR cluster ${CLUSTER_NAME}"

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
    #echo Password $u_password

    if [ -z "${u_fullname}" ]; then
	u_fullname="user "$u
    fi
    if [ -n "${u_email}" ]; then
	re="(^|:)"$u"($|:)"
	create_body
	#echo "#################################"
	#echo -e ${MESSAGE_USER}
	echo -e "$MESSAGE_USER" | mail -s "$SUBJECT" "$u_email"
    else
	echo "No email details given for user $u"
    fi
done

