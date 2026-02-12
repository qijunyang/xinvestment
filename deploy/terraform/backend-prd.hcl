# S3 Backend Configuration for Production Environment
# Usage: terraform init -backend-config=backend-prd.hcl

bucket  = "xinvestment-terraform-state"
key     = "prd/terraform.tfstate"
region  = "us-east-1"
encrypt = true
