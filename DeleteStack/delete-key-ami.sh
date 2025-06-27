#!/bin/bash

# Variables
REGION="ap-northeast-3"  # Your AWS region
KEY_NAME="geneconnect-key"  # Name of the SSH key pair
SSM_AMI_NAME="/geneconnect/latest-ami"  # SSM Parameter name for AMI
SSM_KEY_NAME="/geneconnect/ssh-private-key"  # SSM Parameter name for SSH Key

# Delete SSH key pair from EC2
echo "Deleting EC2 Key Pair: $KEY_NAME..."
aws ec2 delete-key-pair --region "$REGION" --key-name "$KEY_NAME"
if [ $? -eq 0 ]; then
    echo "EC2 Key Pair '$KEY_NAME' deleted successfully."
else
    echo "Failed to delete EC2 Key Pair or it doesn't exist."
fi

# Delete PEM key file from local system
PEM_FILE="${KEY_NAME}.pem"
if [ -f "$PEM_FILE" ]; then
    echo "Deleting local PEM file: $PEM_FILE..."
    rm -f "$PEM_FILE"
    echo "Local PEM file deleted."
else
    echo "PEM file $PEM_FILE not found. Skipping local deletion."
fi

# Delete AMI ID from SSM Parameter Store
echo "Deleting SSM parameter for AMI ID: $SSM_AMI_NAME..."
aws ssm delete-parameter --region "$REGION" --name "$SSM_AMI_NAME"
if [ $? -eq 0 ]; then
    echo "SSM parameter '$SSM_AMI_NAME' deleted successfully."
else
    echo "Failed to delete AMI ID parameter or it doesn't exist."
fi

# Delete SSH Key from SSM Parameter Store
echo "Deleting SSM parameter for SSH Key: $SSM_KEY_NAME..."
aws ssm delete-parameter --region "$REGION" --name "$SSM_KEY_NAME"
if [ $? -eq 0 ]; then
    echo "SSM parameter '$SSM_KEY_NAME' deleted successfully."
else
    echo "Failed to delete SSH key parameter or it doesn't exist."
fi
