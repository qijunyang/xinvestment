#!/bin/bash

# Bash script to create ECR repository
# This only needs to be run once
# Usage: ./setup-ecr.sh [region]

set -e

REGION=${1:-us-east-1}
REPOSITORY_NAME="xinvestment"

echo -e "\033[0;32mCreating ECR repository...\033[0m"
echo -e "\033[0;36mRepository: $REPOSITORY_NAME\033[0m"
echo -e "\033[0;36mRegion: $REGION\033[0m"
echo ""

# Create ECR repository
if aws ecr create-repository \
    --repository-name "$REPOSITORY_NAME" \
    --image-scanning-configuration scanOnPush=true \
    --encryption-configuration encryptionType=AES256 \
    --region "$REGION"; then
    
    echo -e "\033[0;32m✓ ECR repository created successfully\033[0m"
    
    # Get repository URI
    REPO_URI=$(aws ecr describe-repositories \
        --repository-names "$REPOSITORY_NAME" \
        --region "$REGION" \
        --query 'repositories[0].repositoryUri' \
        --output text)
    
    echo ""
    echo -e "\033[0;36mRepository URI: $REPO_URI\033[0m"
    echo ""
    echo -e "\033[0;33mUpdate your terraform-*.tfvars files with:\033[0m"
    echo "  ecr_repository_url = \"$REPO_URI\""
    
    # Set lifecycle policy to keep only last 10 images
    echo ""
    echo -e "\033[0;33mSetting lifecycle policy (keep last 10 images)...\033[0m"
    
    LIFECYCLE_POLICY='{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep last 10 images",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 10
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}'
    
    echo "$LIFECYCLE_POLICY" | aws ecr put-lifecycle-policy \
        --repository-name "$REPOSITORY_NAME" \
        --lifecycle-policy-text file:///dev/stdin \
        --region "$REGION"
    
    if [ $? -eq 0 ]; then
        echo -e "\033[0;32m✓ Lifecycle policy set\033[0m"
    fi
    
else
    echo -e "\033[0;33m✗ Failed to create ECR repository (it may already exist)\033[0m"
    echo ""
    echo -e "\033[0;36mTo get existing repository URI:\033[0m"
    echo "  aws ecr describe-repositories --repository-names $REPOSITORY_NAME --region $REGION"
fi

echo ""
echo -e "\033[0;36mNext steps:\033[0m"
echo "  1. Update terraform-*.tfvars with the repository URI"
echo "  2. Run ./deploy-image.sh dev to build and push the first image"
