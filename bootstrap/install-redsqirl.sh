#!/bin/bash


function change_rs_prop {
prop=`cut -d "=" -f 1 <<< "$1"`
sed -i "/${prop}=/d" $REDSQIRL_PATH/conf/redsqirl_sys.properties
echo $1 >> $REDSQIRL_PATH/conf/redsqirl_sys.properties
}

function jsonval {
	temp=`echo $json | sed 's/\\\\\//\//g' | sed 's/[{}]//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w $prop_master | cut -d ":" -f 2`
	echo ${temp##*|}
}
json=`cat /mnt/var/lib/info/instance.json`
prop_master='isMaster'
ismaster=`jsonval`


if [[ "$ismaster" == "true" ]]; then
    USER_NAMES=$1

    sudo useradd redsqirl -G hadoop -m

    REDSQIRL_TAR=redsqirl-2.7.0-1.2-tomcat.tar.gz
    REDSQIRL_DOWNLOAD_PATH=/opt/${REDSQIRL_TAR}
    REDSQIRL_PATH=/opt/redsqirl-2.7.0-1.2
    REDSQIRL_PORT=8842
    cd /opt
    sudo wget https://s3-eu-west-1.amazonaws.com/redsqirl/v1.2/redsqirl-2.7.0-1.2-tomcat.tar.gz
    sudo tar -zxf $REDSQIRL_DOWNLOAD_PATH
    sudo rm $REDSQIRL_DOWNLOAD_PATH

    TOMCAT_FILE=apache-tomcat-7.0.42

    #change configuration
    namenode=`/sbin/ip addr show eth0 | grep global | cut -d " " -f 6 | cut -d "/" -f 1`
    echo $namenode
    sudo chown -R redsqirl $REDSQIRL_PATH
    #execute install
    sudo -u redsqirl $REDSQIRL_PATH/bin/install.sh << EOF
8842
EOF

    sudo rm $REDSQIRL_PATH/conf/redsqirl_sys.properties
    sudo -u redsqirl touch $REDSQIRL_PATH/conf/redsqirl_sys.properties
    sudo chmod o+rw $REDSQIRL_PATH/conf/redsqirl_sys.properties
    while getopts "p:u:k:" opt; do
        case $opt in
            p)
                change_rs_prop $OPTARG
                ;;
            u)
                USERNAME_CUR=$OPTARG
                sudo useradd $OPTARG -G hadoop -m
                ;;
            k)
                sudo passwd $USERNAME_CUR o
                echo -e "$OPTARG\n$OPTARG" | (sudo passwd --stdin $USERNAME_CUR)
                ;;
        esac
    done


    change_rs_prop "core.pack_manager_url=https\://marketplace.redsqirl.com"
    change_rs_prop "core.hive_jdbc_url=namenode"
    change_rs_prop "core.hive.hive_xml="
    change_rs_prop "core.oozie.oozie_action_queue=default"
    change_rs_prop "core.admin_user=${USER_NAMES}"
    change_rs_prop "core.allow_user_install=true"
    change_rs_prop "core.oozie.oozie_launcher_queue=default"
    change_rs_prop "core.hadoop_home=/usr/lib/hadoop"
    change_rs_prop "core.jobtracker=${namenode}\:8032"
    change_rs_prop "core.namenode=hdfs\://${namenode}\:8020"
    change_rs_prop "core.oozie.oozie_url=http\://${namenode}\:11000/oozie"
    change_rs_prop "core.hcatalog.hive_url=jdbc\:hive2\://${namenode}\:10000"

    sudo chmod o-w $REDSQIRL_PATH/conf/redsqirl_sys.properties

fi
