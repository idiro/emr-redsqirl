#!/bin/bash


EXT_URL=http://idiro-bootstrap.s3.amazonaws.com/tool_tars/ext-2.2.zip

cd /tmp
wget ${EXT_URL}
sudo mv /tmp/ext-2.2.zip /usr/lib/oozie/libext
sudo -u oozie /usr/lib/oozie/bin/oozie-setup.sh prepare-war
sudo /etc/init.d/oozie start
