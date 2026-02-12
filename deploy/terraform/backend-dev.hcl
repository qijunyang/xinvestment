# S3 Backend Configuration for Dev Environment
# Usage: terraform init -backend-config=backend-dev.hcl

bucket  = "xinvestment-terraform-state"
key     = "dev/terraform.tfstate"
region  = "us-east-2"
encrypt = true
