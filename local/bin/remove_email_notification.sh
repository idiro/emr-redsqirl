#!/bin/bash
set -e
function delete_topic {
    local TOPIC_NAME=$1
    local TOPIC_STR=$2
    local TOPIC=`cat ${CLUSTER_HOME}/$TOPIC_NAME`

    aws sns delete-topic --topic-arn "$TOPIC"
    chmod u+w ${CLUSTER_HOME}/$TOPIC_NAME
    rm ${CLUSTER_HOME}/$TOPIC_NAME
    eval $TOPIC_STR=$TOPIC
}

SCRIPT_LOCATION=${BASH_SOURCE[0]}
SCRIPT_PATH="$(cd $(dirname "${SCRIPT_LOCATION}"); pwd -P)/$(basename "${SCRIPT_LOCATION}")"
SCRIPT_PATH="${SCRIPT_PATH%/*}"

CLUSTER_HOME=${SCRIPT_PATH}/..

delete_topic "alarmHDFSFull" TOPIC_AL
delete_topic "alarmHDFSNoData" TOPIC_NODATA
JOBFLOWID=`cat ${CLUSTER_HOME}/jobflowid`
aws cloudwatch delete-alarms \
    --alarm-names "HDFS_$JOBFLOWID"
