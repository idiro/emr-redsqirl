#!/bin/bash

function jsonval {
	temp=`echo $json | sed 's/\\\\\//\//g' | sed 's/[{}]//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w $prop | cut -d ":" -f 2`
	echo ${temp##*|}
}

json=`cat /mnt/var/lib/info/instance.json`
prop='isMaster'
ismaster=`jsonval`


if [[ "$ismaster" == "true" ]]; then

    mkdir tmp
    pushd tmp
    sudo su - -c "R -e \"install.packages('shiny', repos='http://cran.rstudio.com/')\""
    sudo su - -c "R -e \"install.packages('googleVis', repos='http://cran.rstudio.com/')\""
    wget http://download3.rstudio.org/centos5.9/x86_64/shiny-server-1.4.0.756-rh5-x86_64.rpm
    sudo yum install -y --nogpgcheck shiny-server-1.4.0.756-rh5-x86_64.rpm
    sudo mkdir /opt/shiny-server/webapps
    sudo chmod 777 /opt/shiny-server/webapps

    sudo sed -i -e "s#.*site_dir.*#    site_dir /opt/shiny-server/webapps;#g" /etc/shiny-server/shiny-server.conf
    sudo restart shiny-server
    popd

fi
