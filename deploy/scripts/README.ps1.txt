Deploy pipeline quick start (PowerShell):

1. Open PowerShell in project root
2. Run:
   cd deploy\scripts
   .\deploy-pipeline.ps1 -Environment qa

This will:
- Create Terraform state bucket if missing
- Create ECR repo if missing
- Build & push API image
- Deploy Terraform infrastructure
- Build & upload static assets to S3/CloudFront
