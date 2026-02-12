#!/bin/bash

# Bash application deploy pipeline script
# Usage: ./deploy-app.sh <environment> [image_tag]
# Example: ./deploy-app.sh qa
# Example: ./deploy-app.sh prd v1.2.3

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
    echo "Usage: $0 <environment> [image_tag]"
    echo "Environments: dev, qa, uat, stg, prd"
    exit 1
fi

ENVIRONMENT=$1
IMAGE_TAG=$2

if [[ ! "$ENVIRONMENT" =~ ^(dev|qa|uat|stg|prd)$ ]]; then
    error "Invalid environment: $ENVIRONMENT"
    exit 1
fi

SCRIPT_DIR="$(dirname "$0")"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TERRAFORM_DIR="$PROJECT_ROOT/deploy/terraform"
BACKEND_CONFIG="$TERRAFORM_DIR/backend-$ENVIRONMENT.hcl"
VAR_FILE="$TERRAFORM_DIR/terraform-$ENVIRONMENT.tfvars"

info "App deploy pipeline starting for environment: $ENVIRONMENT"
echo ""

# Step 1: Build and push API image
info "Step 1: Build and push API image"
if [ -z "$IMAGE_TAG" ]; then
    "$SCRIPT_DIR/deploy-image.sh" "$ENVIRONMENT"
else
    "$SCRIPT_DIR/deploy-image.sh" "$ENVIRONMENT" "$IMAGE_TAG"
fi

# Step 2: Force ECS service deployment to pull latest image and set desired count
info "Step 2: Update ECS service to use latest image and set desired count to 1"
if [ ! -f "$BACKEND_CONFIG" ]; then
    error "Backend config not found: $BACKEND_CONFIG"
    exit 1
fi
if [ ! -f "$VAR_FILE" ]; then
    error "Var file not found: $VAR_FILE"
    exit 1
fi

AWS_REGION=$(grep 'aws_region' "$VAR_FILE" | cut -d'"' -f2)
if [ -z "$AWS_REGION" ]; then
    error "aws_region not found in $VAR_FILE"
    exit 1
fi

cd "$TERRAFORM_DIR"
terraform init -reconfigure -backend-config="$BACKEND_CONFIG"
CLUSTER_NAME=$(terraform output -raw ecs_cluster_name 2>/dev/null || echo "")
SERVICE_NAME=$(terraform output -raw ecs_service_name 2>/dev/null || echo "")

if [ -z "$CLUSTER_NAME" ] || [ -z "$SERVICE_NAME" ]; then
    error "Could not read ecs_cluster_name or ecs_service_name from Terraform outputs."
    error "Ensure infrastructure is deployed and outputs are available."
    exit 1
fi

aws ecs update-service --cluster "$CLUSTER_NAME" --service "$SERVICE_NAME" --force-new-deployment --desired-count 1 --region "$AWS_REGION" >/dev/null

# Step 3: Deploy static assets to S3/CloudFront
info "Step 3: Deploy static assets to S3/CloudFront (public/dist)"
cd "$PROJECT_ROOT"
BUILD_SCRIPT="build"
if [[ "$ENVIRONMENT" =~ ^(dev|qa|stg|uat)$ ]]; then
    BUILD_SCRIPT="build:dev"
fi

npm run "$BUILD_SCRIPT"
"$SCRIPT_DIR/deploy-static.sh" "$ENVIRONMENT"

echo ""
info "App deploy pipeline complete!"
info "Cluster: $CLUSTER_NAME"
info "Service: $SERVICE_NAME"