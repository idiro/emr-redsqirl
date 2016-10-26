# emr-redsqirl

Create an AWS EMR Cluster with Red Sqirl from a linux system.

1. Create an AWS Cluster
2. Add Red Sqirl users
3. Copy some data on start
3. Send emails to every users with instructions for connecting
4. Shutdown the cluster from command line

## Testing Red Sqirl

For testing Red Sqirl on AWS EMR, it is overkilling to use the script, as you need to set up a smtp server.
Once you have installed and setup [aws](http://docs.aws.amazon.com/cli/latest/userguide/installing.html), you will need to generate a [key](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html)
then you can run the following command.

```
export AWS_USER=myuser
export AWSKEY=/home/myuser/mykey.pem
export AWS_PASSWORD=secret123
aws emr create-cluster --release-label emr-5.0.0 \
  --name "rsTest" --applications Name=Hive Name=Oozie Name=Pig Name=Tez \
  --visible-to-all-users --use-default-role \
  --instance-groups InstanceGroupType=MASTER,InstanceCount=1,InstanceType=m3.xlarge InstanceGroupType=CORE,InstanceCount=2,InstanceType=m3.xlarge \
  --ec2-attributes KeyName=$AWSKEY \
  --bootstrap-action Path=s3://idiro-bootstrap/scripts/install_redsqirl.sh,Args=["${AWS_USER}"],Name="Install Red Sqirl" Path=s3://idiro-bootstrap/scripts/create_users.sh,Name="Create Users",Args=["","${AWS_USER}","","${AWS_PASSWORD}"] Path=s3://idiro-bootstrap/scripts/setup_ssh.sh,Name="Reconfigure SSH" Path=s3://idiro-bootstrap/scripts/install-shiny.sh,Name="Install Shiny" \
  --steps Type=CUSTOM_JAR,Name="HDFS Homes",ActionOnFailure=CONTINUE,Jar="s3://elasticmapreduce/libs/script-runner/script-runner.jar",Args=["s3://idiro-bootstrap/scripts/create_hadoophomes.sh","${AWS_USER}"]
```

## Access to Red Sqirl

Red Sqirl runs on the master nodes, port 8842.
To access it from your browser, please refer to AWS documentation about dynamic port forwarding ([part1](http://docs.aws.amazon.com/ElasticMapReduce/latest/DeveloperGuide/emr-ssh-tunnel.html) and [part2](http://docs.aws.amazon.com/ElasticMapReduce/latest/DeveloperGuide/emr-connect-master-node-proxy.html)).

   The Red Sqirl URL would look like: `http://ec2-###-##-##-###.compute.amazonaws.com:8842/redsqirl`

## The project

The dependencies are:
* Linux (not tested on MAC)
* `mail` command line executable
* [aws](http://docs.aws.amazon.com/cli/latest/userguide/installing.html)
* Permission to create alarms with cloud watch

The configurations (by default in the conf folder):
* `cluster.properties`: setup emails, default aws instances, default users and email address for every users
* `s3.properties`: s3 paths for bootstrap and data.

Usage:
```
#Help
./bin/create_cluster.sh -h
#Start a cluster
./bin/create_cluster.sh -n rs0
#Terminate the cluster rs0
./clusters/rs0/bin/terminate.sh
```
