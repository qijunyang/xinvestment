#!/bin/bash

# Bash script to create Terraform backend S3 bucket
# This only needs to be run once
# Usage: ./setup-terraform-backend.sh

set -e

BUCKET_NAME="xinvestment-terraform-state"
REGION="us-east-1"

echo -e "\033[0;32mSetting up Terraform backend S3 bucket...\033[0m"
echo -e "\033[0;36mBucket: $BUCKET_NAME\033[0m"
echo -e "\033[0;36mRegion: $REGION\033[0m"
echo ""

# Create S3 bucket
echo -e "\033[0;33mCreating S3 bucket...\033[0m"
if aws s3 mb "s3://$BUCKET_NAME" --region "$REGION"; then
    echo -e "\033[0;32m✓ S3 bucket created successfully\033[0m"
    
    # Enable versioning
    echo -e "\033[0;33mEnabling versioning on S3 bucket...\033[0m"
    if aws s3api put-bucket-versioning \
        --bucket "$BUCKET_NAME" \
        --versioning-configuration Status=Enabled; then
        echo -e "\033[0;32m✓ Versioning enabled\033[0m"
    else
        echo -e "\033[0;31m✗ Failed to enable versioning\033[0m"
    fi
else
    echo -e "\033[0;33m✗ Failed to create S3 bucket (it may already exist)\033[0m"
fi

echo ""
echo ""
echo -e "\033[0;32mBackend setup complete!\033[0m"
echo ""
echo -e "\033[0;33mNote: State locking is disabled (no DynamoDB table). Fine for solo/demo work.\033[0m"
echo ""
echo -e "\033[0;36mNext steps:\033[0m"
echo "  1. cd deploy/terraform"
echo "  2. terraform init -backend-config=backend-dev.hcl"
echo "  3. terraform plan -var-file=terraform-dev.tfvars"
