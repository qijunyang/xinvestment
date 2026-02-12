#!/bin/bash

# Deployment script for building and pushing Docker images to ECR
# Usage: ./deploy-image.sh <environment> [image-tag]
# Example: ./deploy-image.sh qa
# Example: ./deploy-image.sh prd v1.2.3

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
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
    echo "Usage: $0 <environment> [image-tag]"
    echo "Environments: dev, qa, uat, stg, prd"
    exit 1
fi

ENVIRONMENT=$1
IMAGE_TAG=${2:-"${ENVIRONMENT}-latest"}

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|qa|uat|stg|prd)$ ]]; then
    error "Invalid environment: $ENVIRONMENT"
    echo "Valid environments: dev, qa, uat, stg, prd"
    exit 1
fi

# Read AWS region and ECR repository URL from terraform variables
SCRIPT_DIR="$(dirname "$0")"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TERRAFORM_DIR="$PROJECT_ROOT/deploy/terraform"
TFVARS_FILE="$TERRAFORM_DIR/terraform-${ENVIRONMENT}.tfvars"

if [ ! -f "$TFVARS_FILE" ]; then
    error "Terraform variables file not found: $TFVARS_FILE"
    exit 1
fi

# Extract ECR repository URL and AWS region from tfvars
ECR_REPO=$(grep 'ecr_repository_url' "$TFVARS_FILE" | cut -d'"' -f2)
AWS_REGION=$(grep 'aws_region' "$TFVARS_FILE" | cut -d'"' -f2)

if [ -z "$ECR_REPO" ] || [ -z "$AWS_REGION" ]; then
    error "Could not extract ECR repository URL or AWS region from $TFVARS_FILE"
    exit 1
fi

info "Environment: $ENVIRONMENT"
info "ECR Repository: $ECR_REPO"
info "AWS Region: $AWS_REGION"
BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
BRANCH_NAME=${BRANCH_NAME//\//-}
SEQUENCE=$(git rev-list --count HEAD 2>/dev/null || echo "0")
BRANCH_TAG="${BRANCH_NAME}-${SEQUENCE}"

info "Image Tag: $IMAGE_TAG"
info "Branch Tag: $BRANCH_TAG"

# Change to project root
cd "$PROJECT_ROOT"

# Build client assets locally first
info "Building client assets locally..."
npm run build
info "Client assets built successfully"

# Build Docker image
info "Building Docker image..."
docker build --no-cache -t xinvestment:${IMAGE_TAG} .

if [ $? -ne 0 ]; then
    error "Docker build failed"
    exit 1
fi

info "Docker image built successfully"

# Security scan Docker image
info "Running security scan on Docker image..."
docker scan --severity high xinvestment:${IMAGE_TAG}

if [ $? -ne 0 ]; then
    error "Docker image security scan failed"
    exit 1
fi

info "Docker image security scan passed"

# Tag image for ECR
info "Tagging image for ECR..."
docker tag xinvestment:${IMAGE_TAG} ${ECR_REPO}:${IMAGE_TAG}
docker tag xinvestment:${IMAGE_TAG} ${ECR_REPO}:${BRANCH_TAG}

# Login to ECR
info "Logging in to ECR..."
ECR_REGISTRY="${ECR_REPO%%/*}"
aws ecr get-login-password --region ${AWS_REGION} | \
    docker login --username AWS --password-stdin ${ECR_REGISTRY}

if [ $? -ne 0 ]; then
    error "ECR login failed"
    exit 1
fi

# Push image to ECR
info "Pushing image to ECR..."
docker push ${ECR_REPO}:${IMAGE_TAG}
docker push ${ECR_REPO}:${BRANCH_TAG}

if [ $? -ne 0 ]; then
    error "Docker push failed"
    exit 1
fi

info "Image pushed successfully!"
info "Image: ${ECR_REPO}:${IMAGE_TAG}"
info "Image: ${ECR_REPO}:${BRANCH_TAG}"

# Update the image_tag in tfvars if using environment-latest tag
if [ "$IMAGE_TAG" == "${ENVIRONMENT}-latest" ]; then
    warn "Remember to update the image_tag in $TFVARS_FILE if needed"
    warn "Current value: $(grep 'image_tag' "$TFVARS_FILE" | cut -d'"' -f2)"
fi

info "Deployment complete!"
echo ""
info "Next steps:"
echo "  1. cd deploy/terraform"
echo "  2. terraform plan -var-file=terraform-${ENVIRONMENT}.tfvars"
echo "  3. terraform apply -var-file=terraform-${ENVIRONMENT}.tfvars"
