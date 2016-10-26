#!/bin/bash

function create_user 
{
    local _USERNAME=$1
    local GROUP=$2
    if [[ -z $GROUP ]]; then
	sudo useradd $_USERNAME -m
    else
	sudo useradd $_USERNAME -G $GROUP -m
    fi
}

function add_key_user
{
    local _USERNAME=$1
    local GROUP=$2
    create_user $_USERNAME $GROUP
    sudo -u $_USERNAME ssh-keygen -t "rsa" -f /home/$_USERNAME/.ssh/id_rsa -N ""
    sudo -u $_USERNAME cp /home/$_USERNAME/.ssh/id_rsa.pub /home/$_USERNAME/.ssh/authorized_keys
    sudo -u $_USERNAME chmod g-w /home/$_USERNAME/.ssh/authorized_keys 
}

function add_key_upload
{
    local _USERNAME=$1
    local GROUP=$2
    add_key_user $_USERNAME $GROUP
    sudo mkdir -p /opt/users/$_USERNAME/
    sudo cp /home/$_USERNAME/.ssh/id_rsa /opt/users/$_USERNAME/rsa_${CLUSTER_NAME}_${_USERNAME}
    sudo chown -R $_USERNAME:$_USERNAME /opt/users/$_USERNAME
    sudo chmod -R 400 /opt/users/$_USERNAME
    sudo rm /home/$_USERNAME/.ssh/id_rsa /home/$_USERNAME/.ssh/id_rsa.pub

}

function jsonval {
	temp=`echo $json | sed 's/\\\\\//\//g' | sed 's/[{}]//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w $prop | cut -d ":" -f 2`
	echo ${temp##*|}
}

json=`cat /mnt/var/lib/info/instance.json`
prop='isMaster'
ismaster=`jsonval`

#Any hadoop user can create/modify tmp folder
sudo chmod g+w /mnt/var/lib/hadoop/tmp
sudo chmod g+w /mnt/var/lib/hive/tmp
sudo chmod g+w /mnt/var/log/apps/hive.log || true
mkdir /mnt/spark || true
mkdir /mnt1/spark || true
sudo chmod g+w /mnt/spark || true
sudo chmod g+w /mnt1/spark || true


CLUSTER_NAME=$1
USERS=$2
RESIZER_MEMBERS=$3
DEFAULT_PASSWORD=$4

if [[ "$ismaster" == "true" ]]
then

    sudo yum --enablerepo=epel -y install pwgen || true
    PASSWD_FILE="/opt/users/password"
    sudo mkdir -p /opt/users
    sudo touch ${PASSWD_FILE}

    add_key_upload "resizer"
    IFS=":"
    for u in $USERS; do
	echo "$u"
	add_key_user $u "hadoop"
	sudo su $u -c "ssh -o StrictHostKeyChecking=no localhost ls"
	PASSWD=${DEFAULT_PASSWORD}
	while [ -z "$PASSWD" ]; do
	    PASSWD=`pwgen -y -n -c -1 10`
	    if [[ $PASSWD =~ ["'"] || $PASSWD =~ ["\\"] ]]; then 
		PASSWD=""
	    fi
	done
	sudo su -c "echo '${PASSWD}' | passwd \"${u}\" --stdin"
	sudo su -c "echo '${u}=${PASSWD}' >> ${PASSWD_FILE}"
    done

    IFS=":"
    for m in $RESIZER_MEMBERS; do
	echo "$m"
	sudo usermod -a -G resizer $m
    done
    sudo chmod 700 ${PASSWD_FILE}
    sudo chmod 700 /opt/users
else
    echo "not master..."
#    IFS=":"
#    for u in $USERS; do
#	echo "$u"
#	create_user $u "hadoop"
#    done
fi
