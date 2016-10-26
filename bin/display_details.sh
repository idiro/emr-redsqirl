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

function display_cluster_details {
    echo
    echo
    echo The jobflow id: $JOBFLOWID
    echo
    echo The master server is: $MASTERPUBLICDNS
    echo
    echo ROOT SSH: ssh -i ${AWSKEYPATH} hadoop@${MASTERPUBLICDNS}
    echo Resizer SSH: ssh -i ${CLUSTER_FOLDER}/users/resizer/rsa_${CLUSTER_NAME}_resizer resizer@$MASTERPUBLICDNS
    echo Port Forwarding: ssh -i ${AWSKEYPATH} -CND 8157 hadoop@$MASTERPUBLICDNS 
    echo
    echo RedSqirl: http://${MASTERPUBLICDNS}:8842/redsqirl
    echo Hue: http://${MASTERPUBLICDNS}:8888
    echo Logs: http://${MASTERPUBLICDNS}:19888/jobhistory/logs
    echo Ganglia: http://${MASTERPUBLICDNS}/ganglia
    echo ResourceManager: http://${MASTERPUBLICDNS}:9026
    echo Namenode: http://${MASTERPUBLICDNS}:9101
    #echo Oozie: http://${MASTERPUBLICDNS}:11000
    #Port datanode: 9035
}

SCRIPT_LOCATION=${BASH_SOURCE[0]}
SCRIPT_PATH="$(cd $(dirname "${SCRIPT_LOCATION}"); pwd -P)/$(basename "${SCRIPT_LOCATION}")"
SCRIPT_PATH="${SCRIPT_PATH%/*}"
HOME_PROJECT=${SCRIPT_PATH}/..

CLUSTER_NAME=$1
CLUSTER_FOLDER=${HOME_PROJECT}/clusters/${CLUSTER_NAME}

if [[ -z "$CLUSTER_NAME" || ! -d ${CLUSTER_FOLDER} ]]; then
    echo "Impossible to create the cluster ${CLUSTER_NAME}"
    exit 1;
fi

JOBFLOWID=`cat ${CLUSTER_FOLDER}/jobflowid`
MASTERPUBLICDNS=`aws emr describe-cluster --cluster-id $JOBFLOWID  | grep "MasterPublicDnsName" | cut -d "\"" -f 4`;

display_cluster_details
