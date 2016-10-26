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


#Update AWS cli
aws emr ssh --cluster-id $JOBFLOWID --key-pair-file $AWSKEYPATH --command "sudo pip install --upgrade awscli" > /dev/null

#Copy Resizer scripts
aws emr ssh --cluster-id $JOBFLOWID --key-pair-file $AWSKEYPATH --command "sudo mkdir -p /opt/resizer" > /dev/null
aws emr ssh --cluster-id $JOBFLOWID --key-pair-file $AWSKEYPATH --command "sudo chmod -R 750 /opt/resizer" > /dev/null
aws emr ssh --cluster-id $JOBFLOWID --key-pair-file $AWSKEYPATH --command "sudo chown resizer:resizer /opt/resizer" > /dev/null

scp -r -i ${CLUSTER_FOLDER}/users/resizer/rsa_${CLUSTER_NAME}_resizer ${SCRIPT_PATH}/../remote/resizer/* resizer@${MASTERPUBLICDNS}:/opt/resizer/
aws emr ssh --cluster-id $JOBFLOWID --key-pair-file $AWSKEYPATH --command "sudo chmod 700 /opt/resizer/conf" > /dev/null
ssh -i ${CLUSTER_FOLDER}/users/resizer/rsa_${CLUSTER_NAME}_resizer resizer@${MASTERPUBLICDNS} "g++ /opt/resizer/src/resize.cpp -o /opt/resizer/bin/resize" > /dev/null

scp -i ${CLUSTER_FOLDER}/users/resizer/rsa_${CLUSTER_NAME}_resizer ${CLUSTER_FOLDER}/jobflowid resizer@${MASTERPUBLICDNS}:/opt/resizer/conf
ssh -i ${CLUSTER_FOLDER}/users/resizer/rsa_${CLUSTER_NAME}_resizer resizer@${MASTERPUBLICDNS} "chmod 750 /opt/resizer/bin"
ssh -i ${CLUSTER_FOLDER}/users/resizer/rsa_${CLUSTER_NAME}_resizer resizer@${MASTERPUBLICDNS} "chmod 500 /opt/resizer/bin/*"
ssh -i ${CLUSTER_FOLDER}/users/resizer/rsa_${CLUSTER_NAME}_resizer resizer@${MASTERPUBLICDNS} "chmod 400 /opt/resizer/conf/*"

ssh -i ${CLUSTER_FOLDER}/users/resizer/rsa_${CLUSTER_NAME}_resizer resizer@${MASTERPUBLICDNS} "chmod g+rx /opt/resizer/bin/resize"
aws emr ssh --cluster-id $JOBFLOWID --key-pair-file $AWSKEYPATH --command "sudo chown root /opt/resizer/bin/resize" > /dev/null
aws emr ssh --cluster-id $JOBFLOWID --key-pair-file $AWSKEYPATH --command "sudo chmod u+s /opt/resizer/bin/resize" > /dev/null
ssh -i ${CLUSTER_FOLDER}/users/resizer/rsa_${CLUSTER_NAME}_resizer resizer@${MASTERPUBLICDNS} "/opt/resizer/bin/configure_aws.sh" > /dev/null
#Problem with growing cluster
#ssh -i ${CLUSTER_FOLDER}/users/resizer/rsa_${CLUSTER_NAME}_resizer resizer@${MASTERPUBLICDNS} "/opt/resizer/bin/schedule_resize.sh" > /dev/null

