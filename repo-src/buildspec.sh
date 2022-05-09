#!/bin/bash
random_file=`cat /proc/sys/kernel/random/uuid`
echo "{\"filename\": \"$random_file\",\"deploymentname\": \"$DEPLOYMENTNAME\",\"bucketname\": \"$BUCKET\" }" > cf_parameters.json
cat cf_parameters.json
mkdir /tmp/lambda
cp lambda/* /tmp/lambda
cd /tmp/lambda
zip ../lambda.zip *
cd ..
aws s3 cp /tmp/lambda.zip s3://$BUCKET/lambda/$random_file
