#!/bin/bash

# Bash deploy pipeline script
# Usage: ./deploy-pipeline.sh <environment>
# Example: ./deploy-pipeline.sh qa

set -e

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

if [ -z "$1" ]; then
    error "Environment argument is required"
    echo "Usage: $0 <environment>"
    echo "Environments: dev, qa, uat, stg, prd"
    exit 1
fi

ENVIRONMENT=$1

if [[ ! "$ENVIRONMENT" =~ ^(dev|qa|uat|stg|prd)$ ]]; then
    error "Invalid environment: $ENVIRONMENT"
    exit 1
fi

SCRIPT_DIR="$(dirname "$0")"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TERRAFORM_DIR="$PROJECT_ROOT/deploy/terraform"
BACKEND_CONFIG="$TERRAFORM_DIR/backend-$ENVIRONMENT.hcl"
VAR_FILE="$TERRAFORM_DIR/terraform-$ENVIRONMENT.tfvars"

info "Deploy pipeline starting for environment: $ENVIRONMENT"
echo ""

# Step 1: Ensure Terraform backend S3 bucket exists
info "Step 1: Ensure Terraform backend S3 bucket exists"
"$SCRIPT_DIR/setup-terraform-backend.sh"

# Step 2: Ensure ECR repository exists
info "Step 2: Ensure ECR repository exists"
if [ ! -f "$VAR_FILE" ]; then
    error "Var file not found: $VAR_FILE"
    exit 1
fi

AWS_REGION=$(grep 'aws_region' "$VAR_FILE" | cut -d'"' -f2)
if [ -z "$AWS_REGION" ]; then
    error "aws_region not found in $VAR_FILE"
    exit 1
fi

"$SCRIPT_DIR/setup-ecr.sh" "$AWS_REGION"

# Step 3: Build and push API image
info "Step 3: Build and push API image"
"$SCRIPT_DIR/deploy-image.sh" "$ENVIRONMENT"

# Step 4: Terraform apply (infra)
info "Step 4: Deploy infrastructure with Terraform"
if [ ! -f "$BACKEND_CONFIG" ]; then
    error "Backend config not found: $BACKEND_CONFIG"
    exit 1
fi

cd "$TERRAFORM_DIR"
terraform init -backend-config="$BACKEND_CONFIG"
terraform apply -var-file="$VAR_FILE"

# Step 5: Deploy static assets to S3/CloudFront
info "Step 5: Deploy static assets to S3/CloudFront"
cd "$PROJECT_ROOT"
npm run build
"$SCRIPT_DIR/deploy-static.sh" "$ENVIRONMENT"

echo ""
info "Deploy pipeline complete!"
echo ""
info "Get URLs with:"
echo "  cd deploy/terraform"
echo "  terraform output cdn_url"
echo "  terraform output api_url"
echo ""
warn "TLS note: CloudFront custom cert must be in us-east-1; ALB cert is in backend_region."
