#!/bin/bash
set -e

function updateFile {
    _file=$1
    _prop=$2
    _value=$3
    newLine="  <property><name>$_prop</name><value>$_value</value></property>"
    if [[ -z `grep "$_prop" $_file` ]]; then
	echo $newLine  >> $_file
	sed -i -e "#</configuration>#d" $_file
	echo "</configuration>"  >> $_file
    else
	sed -i -e "s#.*${_prop}.*#${newLine}#g" $_file
    fi
}

MAPRED_FILE="/home/hadoop/conf/mapred-site.xml"
YARN_FILE="/home/hadoop/conf/yarn-site.xml"

#The script will take the upper limit and do some meaning full rules from it
#for deducing the other values

#Maximum memory allocated for yarn
MAX_MEM=`cat $YARN_FILE | grep yarn.nodemanager.resource.memory-mb | cut -d'>' -f 5 | cut -d'<' -f 1`

#Minimum Memory allocated
if [[ $MAX_MEM -le 5000 ]]; then
    echo "Cluster too small leave as it is"
    exit 0
fi

#Make an instance have 1G min for each container
MIN_MEM_PER_CONTAINER=1024

#Max memory of a map
MAX_MEM_MAP_MAX=2048

#Max memory of a reducer
MAX_MEM_REDUCER_MAX=4096

#Heap size map
HEAPSIZE_MAP="-Xmx1280m"

#Heap size reduce
HEAPSIZE_REDUCE="-Xmx1792m"


#Virtual memory upper limit ratio ( MAX_RAM*ratio = VIRTUAL_MEMORY_MAX)
#Default is 2.1
#yarn.nodemanager.vmem-pmem-ratio

updateFile $YARN_FILE "yarn.scheduler.minimum-allocation-mb" "${MIN_MEM_PER_CONTAINER}"

#Max memory of a map
updateFile $MAPRED_FILE "mapreduce.map.memory.mb" "${MAX_MEM_MAP_MAX}"

#Max memory of a reduce
updateFile $MAPRED_FILE "mapreduce.reduce.memory.mb" "${MAX_MEM_REDUCER_MAX}"


#Heap size of a map
updateFile $MAPRED_FILE "mapreduce.map.java.opts" "${HEAPSIZE_MAP}"


#Heap size of a reduce
updateFile $MAPRED_FILE "mapreduce.reduce.java.opts" "${HEAPSIZE_REDUCE}"

