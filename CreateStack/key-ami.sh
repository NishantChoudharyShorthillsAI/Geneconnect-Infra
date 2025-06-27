#!/bin/bash

# Variables
REGION="ap-northeast-3"  # Change this to your AWS region
SSM_AMI_NAME="/geneconnect/latest-ami"  # SSM Parameter Store Key for AMI
SSM_KEY_NAME="/geneconnect/ssh-private-key"  # SSM Parameter Store Key for SSH Key
KEY_NAME="geneconnect-key"  # SSH Key Pair Name
PRIVATE_KEY_FILE="$KEY_NAME.pem"  # Local file to store private key

# Fetch the latest Ubuntu AMI ID
echo "Fetching the latest Ubuntu AMI ID..."
AMI_ID=$(aws ec2 describe-images --region "$REGION" --owners 099720109477 --filters Name=name,Values=ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-* Name=architecture,Values=x86_64 Name=virtualization-type,Values=hvm Name=root-device-type,Values=ebs  --query 'Images | sort_by(@,&CreationDate) | [-1].ImageId' --output text)

if [[ -z "$AMI_ID" ]]; then
    echo "Failed to fetch AMI ID"
    exit 1
fi

echo "Latest AMI ID: $AMI_ID"

# Store the AMI ID in AWS SSM Parameter Store
echo "Storing AMI ID in AWS SSM Parameter Store..."
aws ssm put-parameter --region "$REGION" \
    --name "$SSM_AMI_NAME" \
    --type "String" \
    --value "$AMI_ID" \
    --overwrite

echo "AMI ID stored successfully in SSM: $SSM_AMI_NAME"

# Check if the SSH Key Pair Exists, If Not Create One
EXISTING_KEY=$(aws ec2 describe-key-pairs --region "$REGION" --query "KeyPairs[?KeyName=='$KEY_NAME'].KeyName" --output text)
if [[ -z "$EXISTING_KEY" ]]; then
    echo "Creating new SSH Key Pair: $KEY_NAME"

    # Create SSH key pair and store private key locally
    aws ec2 create-key-pair --region "$REGION" --key-name "$KEY_NAME" \
        --query 'KeyMaterial' --output text > "$PRIVATE_KEY_FILE"

    # Set correct permissions for security
    chmod 400 "$PRIVATE_KEY_FILE"

    # Store private key in SSM Parameter Store
    aws ssm put-parameter --region "$REGION" \
        --name "$SSM_KEY_NAME" \
        --type "SecureString" \
        --value "$(cat $PRIVATE_KEY_FILE)" \
        --overwrite

    echo "SSH Key stored securely in SSM: $SSM_KEY_NAME"
else
    echo "SSH Key Pair '$KEY_NAME' already exists. Skipping key creation."
fi
