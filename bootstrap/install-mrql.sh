#!/bin/bash
set -e

HOME=/home/hadoop
MRQL_VERSION=0.9.4
MRQL_HOME=/home/hadoop/mrql-${MRQL_VERSION}
MRQL_TAR=mrql-${MRQL_VERSION}-2.4.0.tar.gz 
MRQL_BIN=${MRQL_HOME}/bin
MRQL_CONF=${MRQL_HOME}/conf
URL_CUP=http://mirrors.ibiblio.org/pub/mirrors/maven2/net/sf/squirrel-sql/thirdparty/non-maven/java-cup/11a/java-cup-11a.jar
URL_JLINE=http://central.maven.org/maven2/jline/jline/1.0/jline-1.0.jar
URL=http://idiro-bootstrap.s3.amazonaws.com/tool_tars/mrql-0.9.4-2.4.0.tar.gz
#Install mrql from repository

#sudo yum -y install git
#git clone https://git-wip-us.apache.org/repos/asf/incubator-mrql.git mrql-0.9.4
#sudo wget http://repos.fedorapeople.org/repos/dchen/apache-maven/epel-apache-maven.repo -O /etc/yum.repos.d/epel-apache-maven.repo
#sudo sed -i 's/$releasever/6/g' /etc/yum.repos.d/epel-apache-maven.repo
#sudo yum -y install apache-maven
#sudo ln -s /usr/share/apache-maven/bin/mvn /usr/bin/mvn
#cd mrql-0.9.4
#mvn -Pyarn -Dyarn.version=2.4.0 -Dhadoop.version=2.4.0 clean install 

#Install mrql from pre-prepared file

cd /tmp
wget ${URL}
cd ${HOME}
tar -xzf /tmp/${MRQL_TAR}
rm /tmp/${MRQL_TAR}

cd ${MRQL_HOME}
mkdir lib_external
cd ${MRQL_HOME}/lib_external
wget ${URL_CUP}
wget ${URL_JLINE}

cd ${MRQL_HOME}
MASTER=`cat /home/hadoop/conf/core-site.xml | grep fs.default.name | cut -d'/' -f 4 | cut -d':' -f 1`
sed -i -e "s/localhost/${MASTER}/g" \
 -e 's#${HADOOP_HOME}/share/hadoop#${HADOOP_HOME}/.versions/2.4.0/share/hadoop#g' \
 -e "s#HADOOP_HOME=.*#HADOOP_HOME=${HOME}#g" \
 -e "s#HADOOP_CONFIG=.*#HADOOP_CONFIG=${HOME}/conf#g" \
 -e "s#JAVA_HOME=.*#JAVA_HOME=$JAVA_HOME#g" \
 -e "s#HADOOP_VERSION=.*#HADOOP_VERSION=2.4.0#g" \
 -e "s#CUP_JAR=.*#CUP_JAR=${MRQL_HOME}/lib_external/java-cup-11a.jar#g" \
 -e "s#JLINE_JAR=.*#JLINE_JAR=${MRQL_HOME}/lib_external/jline-1.0.jar#g" \
 -e "s#SPARK_HOME=.*#SPARK_HOME=/home/hadoop/spark#g" \
 -e 's#HAMA_HOME=.*#HAMA_HOME=/home/hadoop/hama-${HAMA_VERSION}#g' \
 ${MRQL_CONF}/mrql-env.sh

sed -i '92i export HADOOP_CONF_DIR=/home/hadoop/conf' ${MRQL_CONF}/mrql-env.sh

echo ' ' >> ${HOME}/.bashrc
echo 'export PATH=/home/hadoop/mrql-0.9.4/bin:${PATH}' >> ${HOME}/.bashrc
