#!/bin/bash

# Deleting AMI SSM Parameter, SSH Key Pair
bash delete-key-ami.sh

# Set region and stack name
REGION="ap-northeast-3"
STACK_NAME="geneconnect-stack"

# Check if stack exists
STACK_STATUS=$(aws cloudformation describe-stacks \
    --region "$REGION" \
    --stack-name "$STACK_NAME" \
    --query "Stacks[0].StackStatus" \
    --output text 2>/dev/null)

if [[ -z "$STACK_STATUS" || "$STACK_STATUS" == "None" || "$STACK_STATUS" == "null" ]]; then
    echo "No stack named '$STACK_NAME' found in region '$REGION'."
    exit 0
else
    echo "Stack '$STACK_NAME' exists with status: $STACK_STATUS"
fi

# Confirm deletion
read -p "Are you sure you want to delete the stack '$STACK_NAME'? Type 'yes' to confirm: " CONFIRM

if [[ "$CONFIRM" != "yes" ]]; then
    echo "Deletion aborted by user."
    exit 0
fi

# Delete the stack
echo "Initiating stack deletion..."
aws cloudformation delete-stack \
    --stack-name "$STACK_NAME" \
    --region "$REGION"

# Wait until deletion is complete
echo "Waiting for stack deletion to complete..."
aws cloudformation wait stack-delete-complete \
    --stack-name "$STACK_NAME" \
    --region "$REGION"

if [ $? -eq 0 ]; then
    echo "Stack '$STACK_NAME' deleted successfully."
else
    echo "Failed to delete stack or it timed out."
fi