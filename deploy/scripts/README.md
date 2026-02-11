# Deployment Scripts

This directory contains helper scripts for deployment.

## Scripts

- `setup-terraform-backend.ps1/.sh` - Create S3 bucket for Terraform state
- `setup-ecr.ps1/.sh` - Create ECR repository
- `deploy-image.ps1/.sh` - Build and push API Docker image to ECR
- `deploy-static.ps1/.sh` - Upload static assets to S3 and invalidate CloudFront
- `deploy-pipeline.ps1/.sh` - Full pipeline: backend setup → image → infra → static

## Deploy Pipeline Usage

```powershell
# Run full pipeline for QA
.\deploy-pipeline.ps1 -Environment qa
```

```bash
# Run full pipeline for QA
./deploy-pipeline.sh qa
```

## Order of Operations

1. Ensure S3 backend exists
2. Ensure ECR exists
3. Build & push API image
4. Terraform apply (creates ALB, ECS, S3, CloudFront, etc.)
5. Build & deploy static assets to S3/CloudFront

This order ensures:
- Terraform can init with remote state
- ECS can pull a valid image
- CloudFront/S3 exist before static assets upload
