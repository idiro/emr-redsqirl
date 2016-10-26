#!/bin/bash
set -e
function jsonval {
	temp=`echo $json | sed 's/\\\\\//\//g' | sed 's/[{}]//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w $prop | cut -d ":" -f 2`
	echo ${temp##*|}
}

HOME=/home/hadoop
HAMA_VERSION="0.6.4"
HAMA_TAR=hama-${HAMA_VERSION}-2.4.0.tar.gz
HAMA_URL=http://idiro-bootstrap.s3.amazonaws.com/tool_tars/hama-0.6.4-2.4.0.tar.gz
HAMA_INIT_URL=http://idiro-bootstrap.s3.amazonaws.com/scripts/init-hama.sh


HAMA_HOME="/home/hadoop/hama-${HAMA_VERSION}"
HAMA_CONF="${HAMA_HOME}/conf"
HAMA_BIN="${HAMA_HOME}/bin"

mkdir ${HOME}/tmp ||true
cd ${HOME}/tmp
wget ${HAMA_INIT_URL}
chmod +x init-hama.sh

cd /tmp/
wget ${HAMA_URL}
cd ${HOME}
tar -xzf /tmp/${HAMA_TAR}
rm /tmp/${HAMA_TAR} 

if [[ -d ${HOME}/hama-${HAMA_VERSION}-2.4.0 ]]; then
    mv ${HOME}/hama-${HAMA_VERSION}-2.4.0 ${HOME}/hama-${HAMA_VERSION}
fi

json=`cat /mnt/var/lib/info/instance.json`
prop='isMaster'
ismaster=`jsonval`

MASTER=`cat /home/hadoop/conf/core-site.xml | grep fs.default.name | cut -d'/' -f 4 | cut -d':' -f 1`
SHUTDOWN_SCRIPT="/mnt/var/lib/instance-controller/public/shutdown-actions/stop-hama.sh"

#Configure hama-site.xml
cp ${HAMA_CONF}/hama-site.xml ${HAMA_CONF}/hama-site.xml.old 

echo "<?xml version=\"1.0\"?>
  <?xml-stylesheet type=\"text/xsl\" href=\"configuration.xsl\"?>
  <configuration>
    <property>
      <name>bsp.master.address</name>
      <value>${MASTER}:40000</value>
      <description>The address of the bsp master server. Either the
      literal string \"local\" or a host:port for distributed mode
      </description>
    </property>

    <property>
      <name>fs.default.name</name>
      <value>hdfs://${MASTER}:9000/</value>
      <description>
        The name of the default file system. Either the literal string
        \"local\" or a host:port for HDFS.
      </description>
    </property>

    <property>
      <name>hama.zookeeper.quorum</name>
      <value>${MASTER}</value>
      <description>Comma separated list of servers in the ZooKeeper Quorum.
      For example, \"host1.mydomain.com,host2.mydomain.com,host3.mydomain.com\".
      By default this is set to localhost for local and pseudo-distributed modes
      of operation. For a fully-distributed setup, this should be set to a full
      list of ZooKeeper quorum servers. If HAMA_MANAGES_ZK is set in hama-env.sh
      this is the list of servers which we will start/stop zookeeper on.
      </description>
    </property>
  </configuration>" > ${HAMA_CONF}/hama-site.xml

#Configure hama-env.sh
cp ${HAMA_CONF}/hama-env.sh ${HAMA_CONF}/hama-env.sh.old 
echo "
export HAMA_HOME=${HAMA_HOME}
export HAMA_LOG_DIR=${HAMA_HOME}/logs
export HAMA_HEAPSIZE=1000
export HAMA_MANAGES_ZK=true" > ${HAMA_CONF}/hama-env.sh

echo ' ' >> ${HOME}/.bashrc
echo 'export PATH=${HOME}/hama-0.6.4/bin:${PATH}' >> ${HOME}/.bashrc

cd /home/hadoop/hama-0.6.4/bin
nohup ${HOME}/tmp/init-hama.sh > ${HOME}/tmp/nohup-hama.txt || true &
exit 0;
