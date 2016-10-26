#!/bin/bash

function createHadoopHome
{
    local _USERNAME=$1
    hadoop fs -mkdir /user/${_USERNAME}
    hadoop fs -chmod 700 /user/${_USERNAME}
    hadoop fs -mkdir /user/${_USERNAME}/mrql /user/${_USERNAME}/mrql-tmp /user/${_USERNAME}/tmp
    hadoop fs -chmod g+rwx /user/${_USERNAME}/mrql /user/${_USERNAME}/mrql-tmp
    hadoop fs -chown -R ${_USERNAME}:${_USERNAME} /user/${_USERNAME}

    hadoop fs -mkdir /share/${_USERNAME}
    hadoop fs -chown ${_USERNAME}:${_USERNAME} /share/${_USERNAME}
}

USERS=$1

hadoop fs -mkdir /share

IFS=":"
for u in $USERS; do
    echo "$u"
    createHadoopHome $u
done

hadoop fs -chmod -R 755 /share
hadoop fs -mkdir /share/common
hadoop fs -chmod 777 /share/common

hadoop fs -mkdir /data
hadoop fs -chmod 755 /data


hadoop fs -chmod 755 /user
hadoop fs -chmod 755 /user/hadoop
hadoop fs -mkdir /user/hadoop/tmp
hadoop fs -chmod 777 /user/hadoop/tmp
hadoop fs -chmod 777 /tmp
hadoop fs -mkdir /spark-logs
hadoop fs -chmod 777 /spark-logs
