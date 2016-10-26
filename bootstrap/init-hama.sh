#!/bin/bash

function jsonval {
	temp=`echo $json | sed 's/\\\\\//\//g' | sed 's/[{}]//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w $prop | cut -d ":" -f 2`
	echo ${temp##*|}
}
HAMA_VERSION="0.6.4"
HAMA_HOME="/home/hadoop/hama-${HAMA_VERSION}"
HAMA_CONF="${HAMA_HOME}/conf"
HAMA_BIN="${HAMA_HOME}/bin"

SHUTDOWN_SCRIPT="/mnt/var/lib/instance-controller/public/shutdown-actions/stop-hama.sh"

json=`cat /mnt/var/lib/info/instance.json`
prop='isMaster'
ismaster=`jsonval`

#Start Daemons
cd ${HAMA_BIN}
. ${HAMA_BIN}/hama-config.sh
while true; do
    if [[ "$ismaster" == "true" ]]; then
	if [[ -n `jps | grep NameNode` ]];then
	    #Kick off BSP Master
	    ${HAMA_BIN}/hama-daemon.sh --config "${HAMA_CONF}" start zookeeper
	    ${HAMA_BIN}/hama-daemon.sh --config "${HAMA_CONF}" start bspmaster
	    echo "#!/bin/bash
${HAMA_BIN}/hama-daemon.sh --config \"${HAMA_CONF}\" stop bspmaster
${HAMA_BIN}/hama-daemon.sh --config \"${HAMA_CONF}\" stop zookeeper" > ${SHUTDOWN_SCRIPT}
	    exit 0;
	fi
    else
	if [[ -n `jps | grep DataNode` ]];then
	    #Make sure that Master is running
	    sleep 30
	    #Kick off groom server
	    ${HAMA_BIN}/hama-daemon.sh --config "${HAMA_CONF}" start groom
	    echo "#!/bin/bash
${HAMA_BIN}/hama-daemon.sh --config \"${HAMA_CONF}\" stop groom" > ${SHUTDOWN_SCRIPT}
	    exit 0;
	fi
    fi
    sleep 20
done
