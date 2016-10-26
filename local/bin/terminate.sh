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
CLUSTER_HOME=$(dirname $SCRIPT_PATH)
JOBFLOWID=`cat ${CLUSTER_HOME}/jobflowid`
${SCRIPT_PATH}/remove_email_notification.sh
aws emr terminate-clusters --cluster-ids $JOBFLOWID

${SCRIPT_PATH}/send_email.sh

chmod -R u+w ${CLUSTER_HOME}
rm -r ${CLUSTER_HOME}
