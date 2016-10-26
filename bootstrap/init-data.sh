#!/bin/bash

function downloadData()
{
    local _s3Dir=$1
    local _hdfsDir=$2
    /home/hadoop/bin/hadoop distcp "${_s3Dir}" ${_hdfsDir}/
}

USERS=$1
DATASET=$2
HDFS_DATA_DIR=/data
S3_DIR="s3://idiro-data"
IFS=":"
for d in $DATASET; do
    downloadData "${S3_DIR}/$d" ${HDFS_DATA_DIR}
done

for u in $USERS; do
    if [[ -n "`aws s3 ls s3://idiro-users | grep $u`" ]]; then
	downloadData s3://idiro-users/$u/* /user/$u
	hadoop fs -chown -R $u:$u /user/$u/*
    fi
done
