#!/bin/bash
# set -x
# Variables
BUCKET_NAME="s3-bucket-trial2"
TABLE_NAME="dynamodb-table-trial2"
REGION="eu-west-2"
PROFILE="euteam1" 

# Function to create an S3 bucket
create_s3_bucket() {
  echo "Creating S3 bucket: $BUCKET_NAME"
  
  aws s3api create-bucket \
    --bucket $BUCKET_NAME \
    --region $REGION \
    --profile $PROFILE \
    --create-bucket-configuration LocationConstraint=$REGION

  if [ $? -eq 0 ]; then
    echo "S3 bucket $BUCKET_NAME created successfully."
  else
    echo "Failed to create S3 bucket."
  fi
}

# Function to create a DynamoDB table
create_dynamodb_table() {
  echo "Creating DynamoDB table: $TABLE_NAME"
  
  aws dynamodb create-table \
    --table-name $TABLE_NAME \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --region $REGION \
    --profile $PROFILE 

  if [ $? -eq 0 ]; then
    echo "DynamoDB table $TABLE_NAME created successfully."
  else
    echo "Failed to create DynamoDB table."
  fi
}

# Create S3 bucket and DynamoDB table
create_s3_bucket
create_dynamodb_table

# # # # Create a Jenkins server
cd ./jenkins
terraform init
terraform fmt --recursive
terraform validate
terraform apply -auto-approve