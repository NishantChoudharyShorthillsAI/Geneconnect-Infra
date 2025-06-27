#!/bin/bash

# Set region and stack name
REGION="ap-northeast-3"
STACK_NAME="geneconnect-stack"

# Run script that creates PEM key and AMI ID
bash key-ami.sh

# Get default VPC ID
VPC_ID=$(aws ec2 describe-vpcs \
    --region "$REGION" \
    --filters Name=isDefault,Values=true \
    --query "Vpcs[0].VpcId" \
    --output text)

# Fetch all subnets in the VPC along with their AZ
ALL_SUBNETS=$(aws ec2 describe-subnets \
    --region "$REGION" \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query "Subnets[*].[SubnetId,AvailabilityZone]" \
    --output text)

# Initialize variables
SUBNET_ID_A=""
SUBNET_ID_B=""

# Pick first subnet in AZ ending in 'a' and 'b'
while read -r SUBNET_ID AZ; do
    if [[ -z "$SUBNET_ID_A" && "$AZ" == *"a" ]]; then
        SUBNET_ID_A=$SUBNET_ID
    elif [[ -z "$SUBNET_ID_B" && "$AZ" == *"b" ]]; then
        SUBNET_ID_B=$SUBNET_ID
    fi
done <<< "$ALL_SUBNETS"

# Show results
echo "Using VPC ID: $VPC_ID"
echo "Subnet in AZ A: $SUBNET_ID_A"
echo "Subnet in AZ B: $SUBNET_ID_B"


# Deploy CloudFormation stack
aws cloudformation create-stack \
    --stack-name "$STACK_NAME" \
    --template-body file://geneconnectStack.yml \
    --region "$REGION" \
    --parameters \
        ParameterKey=VpcId,ParameterValue="$VPC_ID" \
        ParameterKey=SubnetIdA,ParameterValue="$SUBNET_ID_A" \
        ParameterKey=SubnetIdB,ParameterValue="$SUBNET_ID_B" \
        ParameterKey=InstanceType,ParameterValue="t2.large" \
        ParameterKey=KeyName,ParameterValue="geneconnect-key" \
        ParameterKey=S3BucketName,ParameterValue="pedigree-project-$(date +%s)" \
        ParameterKey=MasterUsername,ParameterValue="admin"
