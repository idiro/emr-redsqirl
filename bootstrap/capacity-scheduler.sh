#!/bin/bash

CAP_FILE="/home/hadoop/conf/capacity-scheduler.xml"

#backup
cp ${CAP_FILE} ${CAP_FILE}.old

#Change node locality
#LINE_NB=`cat ${CAP_FILE} | grep -n yarn.scheduler.capacity.node-locality-delay | cut -d':' -f 1`
#LINE_NB=`echo "${LINE_NB}+1" | bc`
#sed -i "${LINE_NB}s#.*#        <value>40</value>#" ${CAP_FILE}

DEFAULT_OOZIE_CAP=25
CAPACITY_OOZIE=$1

re='^[1-9][0-9]*$'
if [[ -z $CAPACITY_OOZIE ]]; then
    CAPACITY_OOZIE=$DEFAULT_OOZIE_CAP
elif ! [[ "$CAPACITY_OOZIE" =~ $re ]]; then
    CAPACITY_OOZIE=$DEFAULT_OOZIE_CAP
fi

CAPACITY_DEFAULT=`echo "100 - $CAPACITY_OOZIE" | bc`


echo "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>
<configuration>

    <!-- Global properties -->
    <property>
        <name>yarn.scheduler.capacity.maximum-applications</name>
        <value>10000</value>
        <description>
      Maximum number of applications that can be pending and running.
    </description>
    </property>
    <property>
        <name>yarn.scheduler.capacity.maximum-am-resource-percent</name>
        <value>0.2</value>
        <description>
      Maximum percent of resources in the cluster which can be used to run 
      application masters i.e. controls number of concurrent running
      applications.
    </description>
    </property>
    <property>
        <name>yarn.scheduler.capacity.resource-calculator</name>
        <value>org.apache.hadoop.yarn.util.resource.DefaultResourceCalculator</value>
        <description>
      The ResourceCalculator implementation to be used to compare 
      Resources in the scheduler.
      The default i.e. DefaultResourceCalculator only uses Memory while
      DominantResourceCalculator uses dominant-resource to compare 
      multi-dimensional resources such as Memory, CPU etc.
    </description>
    </property>
    <property>
        <name>yarn.scheduler.capacity.node-locality-delay</name>
        <value>40</value>
        <description>
      Number of missed scheduling opportunities after which the CapacityScheduler 
      attempts to schedule rack-local containers. 
      Typically this should be set to number of nodes in the cluster, By default is setting 
      approximately number of nodes in one rack which is 40.
    </description>
    </property>


    <!-- Root queue -->
    <property>
	<name>yarn.scheduler.capacity.root.queues</name>
	<value>default,ooziequeue</value>
	<description>The queues at the this level (root is the root queue).
	</description>
    </property>

    <!-- Queues -->
    <property>
	<name>yarn.scheduler.capacity.root.default.capacity</name>
	<value>$CAPACITY_DEFAULT</value>
    </property>
    <property>
	<name>yarn.scheduler.capacity.root.ooziequeue.capacity</name>
	<value>$CAPACITY_OOZIE</value>
    </property>
    <property>
	<name>yarn.scheduler.capacity.root.default.maximum-capacity</name>
	<value>-1</value>
    </property>
    <property>
	<name>yarn.scheduler.capacity.root.ooziequeue.maximum-capacity</name>
	<value>$CAPACITY_OOZIE</value>
    </property>
    <property>
	<name>yarn.scheduler.capacity.root.default.minimum-user-limit-percent</name>
	<value>100</value>
    </property>
    <property>
	<name>yarn.scheduler.capacity.root.ooziequeue.minimum-user-limit-percent</name>
	<value>100</value>
    </property>
    <property>
	<name>yarn.scheduler.capacity.root.default.user-limit-factor</name>
	<value>1</value>
    </property>
    <property>
	<name>yarn.scheduler.capacity.root.ooziequeue.user-limit-factor</name>
	<value>1</value>
    </property>
    <property>
	<name>yarn.scheduler.capacity.root.default.state</name>
	<value>RUNNING</value>
	<description>
	    The state of the default queue. State can be one of RUNNING or STOPPED.
	</description>
    </property>
    <property>
	<name>yarn.scheduler.capacity.root.ooziequeue.state</name>
	<value>RUNNING</value>
	<description>
	    The state of the default queue. State can be one of RUNNING or STOPPED.
	</description>
    </property>
    <property>
	<name>yarn.scheduler.capacity.root.default.acl_submit_applications</name>
	<value>*</value>
	<description>
	    The ACL of who can submit jobs to the default queue.
	</description>
    </property>
    <property>
	<name>yarn.scheduler.capacity.root.ooziequeue.acl_submit_applications</name>
	<value>*</value>
	<description>
	    The ACL of who can submit jobs to the oozie queue.
	</description>
    </property>
    <property>
	<name>yarn.scheduler.capacity.root.default.acl_administer_queue</name>
	<value>*</value>
	<description>
	    The ACL of who can administer jobs on the default queue.
	</description>
    </property>
    <property>
	<name>yarn.scheduler.capacity.root.ooziequeue.acl_administer_queue</name>
	<value>*</value>
	<description>
	    The ACL of who can administer jobs on the oozie queue.
	</description>
    </property>

</configuration>" > ${CAP_FILE}

