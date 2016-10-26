#!/bin/bash
#######################################################
#### In order for redsqirl user to login, passwords over ssh has to be enable

function jsonval {
	temp=`echo $json | sed 's/\\\\\//\//g' | sed 's/[{}]//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w $prop | cut -d ":" -f 2`
	echo ${temp##*|}
}

json=`cat /mnt/var/lib/info/instance.json`
prop='isMaster'
ismaster=`jsonval`

if [[ "$ismaster" == "true" ]]
then

    #Update SSH
    sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.old
    sudo sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config
    sudo sed -i "s/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/g" /etc/ssh/sshd_config
    sudo sed -i "s/#ClientAliveInterval 0/ClientAliveInterval 30/g" /etc/ssh/sshd_config
    sudo sed -i "s/#ClientAliveCountMax 3/ClientAliveCountMax 5/g" /etc/ssh/sshd_config

    sudo su -c 'echo "sshd : localhost : allow" >> /etc/hosts.allow'
    sudo su -c 'echo "sshd : 89.101.87.23 : allow" >> /etc/hosts.allow'
    sudo su -c 'echo "sshd : 211.30.221.44 : allow" >> /etc/hosts.allow'
    sudo su -c 'echo "sshd : ALL : allow" >> /etc/hosts.allow'

    #sudo service ssh restart
    sudo /etc/init.d/sshd restart

else
    echo "not master... skipping"
fi
