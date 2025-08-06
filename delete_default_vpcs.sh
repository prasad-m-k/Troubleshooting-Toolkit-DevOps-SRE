#/bin/bash

export REGIONS=$(aws ec2 describe-regions | jq -r ".Regions[].RegionName")

echo "Listing \"Default\" vpcs in each regions"
for region in $REGIONS; do
    # list vpcs
    echo $region
    aws --region=$region ec2 describe-vpcs | jq ".Vpcs[]|{is_default: .IsDefault, cidr: .CidrBlock, id: .VpcId} | select(.is_default)"
done

read -p "Are you sure? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    for region in $REGIONS ; do
        echo "Deleting from the region: $region"
        # list vpcs
        export IDs=$(aws --region=$region ec2 describe-vpcs | jq -r ".Vpcs[]|{is_default: .IsDefault, id: .VpcId} | select(.is_default) | .id")
        for id in "$IDs" ; do
            if [ -z "$id" ] ; then
                continue
            fi

            # Delete igws
            for igw in `aws --region=$region ec2 describe-internet-gateways | jq -r ".InternetGateways[] | {id: .InternetGatewayId, vpc: .Attachments[0].VpcId} | select(.vpc == \"$id\") | .id"` ; do
                echo "Deleting igw $region $id $igw"
                aws --region=$region ec2 detach-internet-gateway --internet-gateway-id=$igw --vpc-id=$id
                aws --region=$region ec2 delete-internet-gateway --internet-gateway-id=$igw
            done

            # Delete subnets
            for sub in `aws --region=$region ec2 describe-subnets | jq -r ".Subnets[] | {id: .SubnetId, vpc: .VpcId} | select(.vpc == \"$id\") | .id"` ; do
                echo "Deleting subnet $region $id $sub"
                aws --region=$region ec2 delete-subnet --subnet-id=$sub
            done

            echo "Deleting vpc $region $id"
            aws --region=$region ec2 delete-vpc --vpc-id=$id
        done
    done

fi
