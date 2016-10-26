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

SCRIPT_LOCATION=${BASH_SOURCE[0]}
SCRIPT_PATH="$(cd $(dirname "${SCRIPT_LOCATION}"); pwd -P)/$(basename "${SCRIPT_LOCATION}")"
SCRIPT_PATH="${SCRIPT_PATH%/*}"

HOME_PROJECT=${SCRIPT_PATH}/..

CLUSTER_NAME=$1
CLUSTER_FOLDER=${HOME_PROJECT}/clusters/${CLUSTER_NAME}

if [[ -z "$CLUSTER_NAME" || ! -d ${CLUSTER_FOLDER} ]]; then
    echo "The cluster ${CLUSTER_NAME} does not exist"
    exit 1;
fi

JOBFLOWID=`cat ${CLUSTER_FOLDER}/jobflowid`
MASTERPUBLICDNS=`aws emr describe-cluster --cluster-id $JOBFLOWID  | grep "MasterPublicDnsName" | cut -d "\"" -f 4`;

chmod -R u+w ${CLUSTER_FOLDER}/users ||true
rm -rf ${CLUSTER_FOLDER}/users ||true

aws emr ssh --cluster-id $JOBFLOWID --key-pair-file $AWSKEYPATH --command "sudo cp -r /opt/users/ /home/hadoop"
aws emr ssh --cluster-id $JOBFLOWID --key-pair-file $AWSKEYPATH --command "sudo chown -R hadoop:hadoop /home/hadoop/users"
aws emr ssh --cluster-id $JOBFLOWID --key-pair-file $AWSKEYPATH --command "sudo chmod -R u+rwx /home/hadoop/users/*"
aws emr ssh --cluster-id $JOBFLOWID --key-pair-file $AWSKEYPATH --command "sudo chmod -R u+rw /home/hadoop/users"
scp -r -i $AWSKEYPATH hadoop@${MASTERPUBLICDNS}:users ${CLUSTER_FOLDER}
aws emr ssh --cluster-id $JOBFLOWID --key-pair-file $AWSKEYPATH --command "sudo rm -r /home/hadoop/users"

