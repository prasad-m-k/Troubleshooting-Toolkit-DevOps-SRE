#!/bin/bash

echo "Listing VPCs in all AWS regions:"

for region in $(aws ec2 describe-regions --output text|awk '{print $4}' ); do
    echo "--- Region: $region ---"
    aws ec2 describe-vpcs --region "$region" --output text #--query 'Vpcs.[Tags[?Key==`Name`].Value |,CidrBlock,VpcId,IsDefault]'
    echo ""
done
