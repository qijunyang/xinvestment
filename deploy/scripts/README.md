# Deployment Scripts

This directory contains helper scripts for deployment.

## Scripts

- setup-terraform-backend.ps1/.sh - Create S3 bucket for Terraform state
- setup-ecr.ps1/.sh - Create ECR repository
- deploy-image.ps1/.sh - Build and push API Docker image to ECR
- deploy-static.ps1/.sh - Upload static assets to S3 and invalidate CloudFront
- deploy-infra.ps1/.sh - Infra pipeline: backend setup -> ECR setup -> terraform apply
- deploy-app.ps1/.sh - App pipeline: build/push image -> force ECS service deployment -> static deploy
- destroy-infra.ps1/.sh - Infra teardown: empty S3 assets (including versions) -> terraform destroy
- destroy-app.ps1/.sh - App teardown: scale ECS service to 0

## Deploy Pipeline Usage

```powershell
# Run infra pipeline for QA
.\deploy-infra.ps1 -Environment qa

# Run app pipeline for QA
.\deploy-app.ps1 -Environment qa
```

```bash
# Run infra pipeline for QA
./deploy-infra.sh qa

# Run app pipeline for QA
./deploy-app.sh qa
```

## Order of Operations

1. Infra: Ensure S3 backend exists
2. Infra: Ensure ECR exists
3. Infra: Terraform apply (creates ALB, ECS, S3, CloudFront, etc.)
4. App: Build and push API image
5. App: Force ECS service deployment
6. App: Build and deploy static assets to S3/CloudFront

This order ensures:
- Terraform can init with remote state
- ECS can pull a valid image
- CloudFront/S3 exist before static assets upload

## Destroy Pipeline Usage

```powershell
.\destroy-infra.ps1 -Environment dev

.\destroy-app.ps1 -Environment dev
```

```bash
./destroy-infra.sh dev

./destroy-app.sh dev
```

Notes:
- destroy-infra empties the static S3 bucket first to avoid destroy errors.
- destroy-app only scales the ECS service to 0 and leaves infra intact.
- ECR repository and Terraform state bucket are not deleted by these scripts.
