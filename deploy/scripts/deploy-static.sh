#!/bin/bash

# Bash script to deploy static assets to S3 and invalidate CloudFront
# Usage: ./deploy-static.sh <environment>
# Example: ./deploy-static.sh qa

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Check arguments
if [ -z "$1" ]; then
    error "Environment argument is required"
    echo "Usage: $0 <environment>"
    echo "Environments: dev, qa, uat, stg, prd"
    exit 1
fi

ENVIRONMENT=$1

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|qa|uat|stg|prd)$ ]]; then
    error "Invalid environment: $ENVIRONMENT"
    echo "Valid environments: dev, qa, uat, stg, prd"
    exit 1
fi

info "Deploying static assets for environment: $ENVIRONMENT"

# Change to project root
cd "$(dirname "$0")/../.."

# Check if dist folder exists
if [ ! -d "dist" ]; then
    error "dist folder not found. Please run 'npm run build' first."
    exit 1
fi

# Get S3 bucket and CloudFront distribution ID from Terraform output
info "Getting infrastructure info from Terraform..."
cd deploy/terraform

TERRAFORM_OUTPUT=$(terraform output -json)
if [ $? -ne 0 ]; then
    error "Failed to get Terraform outputs. Make sure infrastructure is deployed."
    exit 1
fi

S3_BUCKET=$(echo "$TERRAFORM_OUTPUT" | jq -r '.s3_static_assets_bucket.value')
CLOUDFRONT_DIST_ID=$(echo "$TERRAFORM_OUTPUT" | jq -r '.cloudfront_distribution_id.value')
CDN_URL=$(echo "$TERRAFORM_OUTPUT" | jq -r '.cdn_url.value')

if [ -z "$S3_BUCKET" ] || [ -z "$CLOUDFRONT_DIST_ID" ] || [ "$S3_BUCKET" = "null" ] || [ "$CLOUDFRONT_DIST_ID" = "null" ]; then
    error "Could not retrieve S3 bucket or CloudFront distribution ID from Terraform."
    exit 1
fi

info "S3 Bucket: $S3_BUCKET"
info "CloudFront Distribution: $CLOUDFRONT_DIST_ID"
info "CDN URL: $CDN_URL"

# Return to project root
cd ../..

# Sync dist folder to S3
info "Uploading static assets to S3..."
aws s3 sync dist/ "s3://$S3_BUCKET/" \
    --delete \
    --cache-control "public,max-age=31536000,immutable" \
    --exclude "*.html" \
    --exclude "*.map"

if [ $? -ne 0 ]; then
    error "Failed to sync assets to S3"
    exit 1
fi

# Upload HTML files with shorter cache duration
info "Uploading HTML files with shorter cache..."
aws s3 sync dist/ "s3://$S3_BUCKET/" \
    --exclude "*" \
    --include "*.html" \
    --cache-control "public,max-age=300"

if [ $? -ne 0 ]; then
    error "Failed to upload HTML files to S3"
    exit 1
fi

info "Static assets uploaded successfully!"

# Create CloudFront invalidation
info "Creating CloudFront invalidation..."
INVALIDATION_ID=$(aws cloudfront create-invalidation \
    --distribution-id "$CLOUDFRONT_DIST_ID" \
    --paths "/*" \
    --query 'Invalidation.Id' \
    --output text)

if [ $? -ne 0 ]; then
    error "Failed to create CloudFront invalidation"
    exit 1
fi

info "CloudFront invalidation created: $INVALIDATION_ID"
info "Invalidation may take a few minutes to complete."

echo ""
info "Deployment complete!"
echo ""
info "CDN URL: $CDN_URL"
info "You can check invalidation status with:"
echo "  aws cloudfront get-invalidation --distribution-id $CLOUDFRONT_DIST_ID --id $INVALIDATION_ID"
