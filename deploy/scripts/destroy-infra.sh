#!/bin/bash

# Bash infrastructure destroy pipeline script
# Usage: ./destroy-infra.sh <environment>
# Example: ./destroy-infra.sh dev

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

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
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

info "Destroy infra pipeline starting for environment: $ENVIRONMENT"
echo ""

if [ ! -f "$BACKEND_CONFIG" ]; then
    error "Backend config not found: $BACKEND_CONFIG"
    exit 1
fi
if [ ! -f "$VAR_FILE" ]; then
    error "Var file not found: $VAR_FILE"
    exit 1
fi


cd "$TERRAFORM_DIR"

terraform init -reconfigure -backend-config="$BACKEND_CONFIG"

# Empty static assets bucket (if it exists) to avoid destroy errors
info "Checking static assets bucket..."
BUCKET_NAME=$(terraform output -raw s3_static_assets_bucket 2>/dev/null || echo "")

delete_bucket_versions() {
    local bucket="$1"
    if ! aws s3api head-bucket --bucket "$bucket" >/dev/null 2>&1; then
        warn "Bucket not found: $bucket"
        return 0
    fi

    export BUCKET_NAME
    python - <<'PY'
import json
import os
import subprocess
import tempfile

bucket = os.environ.get("BUCKET_NAME")
resp = subprocess.check_output(["aws", "s3api", "list-object-versions", "--bucket", bucket])
data = json.loads(resp)
items = []
for key in ("Versions", "DeleteMarkers"):
    items.extend(data.get(key, []))
if not items:
    print("Bucket already empty.")
    raise SystemExit(0)

def chunks(seq, size):
    for i in range(0, len(seq), size):
        yield seq[i:i + size]

for chunk in chunks(items, 1000):
    payload = {
        "Objects": [{"Key": item["Key"], "VersionId": item["VersionId"]} for item in chunk],
        "Quiet": True,
    }
    with tempfile.NamedTemporaryFile("w", delete=False) as fp:
        json.dump(payload, fp)
        name = fp.name
    subprocess.check_call(["aws", "s3api", "delete-objects", "--bucket", bucket, "--delete", f"file://{name}"])
    os.unlink(name)
print(f"Deleted {len(items)} object versions/delete markers from {bucket}")
PY
}

if [ -z "$BUCKET_NAME" ]; then
    warn "S3 bucket output not found (skipping empty step)"
else
    info "Emptying S3 bucket: $BUCKET_NAME"
    delete_bucket_versions "$BUCKET_NAME"
fi

info "Destroying Terraform-managed resources..."
terraform destroy -var-file="$VAR_FILE"

echo ""
info "Destroy infra pipeline complete!"
warn "Note: ECR repository and Terraform state bucket are NOT deleted."