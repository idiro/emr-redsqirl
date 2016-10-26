#!/bin/bash

MRQL_VERSION=0.9.4
MRQL_HOME=/home/hadoop/mrql-${MRQL_VERSION}
MRQL_BIN=${MRQL_HOME}/bin
MRQL_RMAT=${MRQL_HOME}/queries/RMAT.mrql

MRQL_LOGDIR=/home/hadoop/tmp
MRQL_LOG=$MRQL_LOGDIR/init-mrql.log
mkdir $MRQL_LOGDIR ||true

#Create the full jars and check if MRQL is working
touch $MRQL_LOG ||true
echo "Execute Map/Red" >> $MRQL_LOG
${MRQL_BIN}/mrql -dist ${MRQL_RMAT} 10 100 >> $MRQL_LOG
hadoop fs -rm -r /user/hadoop/tmp/*
echo "Execute Spark" >> $MRQL_LOG
${MRQL_BIN}/mrql.spark -dist ${MRQL_RMAT} 10 100 >> $MRQL_LOG
hadoop fs -rm -r /user/hadoop/tmp/*
echo "Execute BSP" >> $MRQL_LOG
${MRQL_BIN}/mrql.bsp -dist ${MRQL_RMAT} 10 100 >> $MRQL_LOG
hadoop fs -rm -r /user/hadoop/tmp/*
