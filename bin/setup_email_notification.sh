#!/bin/bash
set -e
function create_topic {
    local TOPIC_NAME=$1
    local TOPIC_STR=$2
    #Create an email topic
    aws sns create-topic --name "$TOPIC_NAME" \
	| grep TopicArn | cut -d "\"" -f 4 >> ${CLUSTER_FOLDER}/$TOPIC_NAME

    local TOPIC=`cat ${CLUSTER_FOLDER}/$TOPIC_NAME`
    chmod 400 ${CLUSTER_FOLDER}/$TOPIC_NAME
    #Join an email address
    aws sns subscribe --topic-arn $TOPIC --protocol email --notification-endpoint $EMAIL
    #Have to confirm by email
    echo "Show list: aws sns list-subscriptions-by-topic --topic-arn $TOPIC" 
    #Confirm it is working
    echo "Send an email: aws sns publish --message 'Verification' --topic $TOPIC"
    eval $TOPIC_STR=$TOPIC
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
EMAIL=$2
if [[ -z $EMAIL ]]; then
    echo Second argument needed with the email address
    echo No email specified
    exit 1;
fi
create_topic "alarmHDFSFull" TOPIC_AL
create_topic "alarmHDFSNoData" TOPIC_NODATA
echo "Join $EMAIL to the topic"
aws cloudwatch put-metric-alarm \
    --alarm-name "HDFS_$JOBFLOWID" \
    --alarm-description "Alarm when HDFS go over 80% for $JOBFLOWID" \
    --metric-name HDFSUtilization \
    --namespace AWS/ElasticMapReduce \
    --statistic Average \
    --period 300 \
    --threshold 0.8 \
    --comparison-operator GreaterThanThreshold \
    --dimensions "Name=JobFlowId,Value=$JOBFLOWID" \
    --evaluation-periods 3 \
    --alarm-actions $TOPIC_AL \
    --insufficient-data-actions $TOPIC_NODATA 
