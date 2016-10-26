#!/bin/bash
set -x -e

SPARK_102=http://idiro-bootstrap.s3.amazonaws.com/scripts/install-spark-1.0.2.py

GANGLIASCRIPT=http://support.elasticmapreduce.s3.amazonaws.com/spark/install-ganglia-metrics
INSTALLGANGLIA=0

SPARK_MAX_SCRIPT=http://support.elasticmapreduce.s3.amazonaws.com/spark/maximize-spark-default-config
SPARK_MAX=0

REQUESTED_VERSION="1.4.1"
while getopts "gb:x" opt; do
  case $opt in
    v)
      REQUESTED_VERSION=$OPTARG
      ;;
    g)
      INSTALLGANGLIA=1
      ;;
    b)
      SPARK_build=$OPTARG
      ;;
    x)
      SPARK_MAX=1
      ;;
  esac
done

echo "This script installs the third-party software stack Spark on an EMR cluster."
echo "Requested Spark version: $REQUESTED_VERSION"

wget -O install-spark-script $SPARK_102
python install-spark-script BA
#===
echo "Spark install complete"

if [ $INSTALLGANGLIA -eq 1 ]
then
	wget -O install-ganglia-metrics $GANGLIASCRIPT
	bash install-ganglia-metrics
fi

if [ $SPARK_MAX -eq 1 ]
then
        wget -O maximize-spark-default-config $SPARK_MAX_SCRIPT
        bash maximize-spark-default-config
fi



exit 0
