#!/bin/bash

# Bash application destroy pipeline script
# Usage: ./destroy-app.sh <environment>
# Example: ./destroy-app.sh dev

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

info "Destroy app pipeline starting for environment: $ENVIRONMENT"
echo ""

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

aws ecs update-service --cluster "$CLUSTER_NAME" --service "$SERVICE_NAME" --desired-count 0 --region "$AWS_REGION" >/dev/null

echo ""
info "Destroy app pipeline complete!"
info "Cluster: $CLUSTER_NAME"
info "Service: $SERVICE_NAME"