# S3 Backend Configuration for QA Environment
# Usage: terraform init -backend-config=backend-qa.hcl

bucket  = "xinvestment-terraform-state"
key     = "qa/terraform.tfstate"
region  = "us-east-1"
encrypt = true
