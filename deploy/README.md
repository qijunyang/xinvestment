# Xinvestment Deployment Guide

This directory contains deployment configurations and scripts for the Xinvestment application.

## Architecture

The application uses a hybrid architecture:
- **CloudFront + S3**: Serves static assets (HTML, CSS, JS bundles)
- **ALB + ECS Fargate**: Serves API endpoints

## Multi-Region Note

CloudFront is fixed to **us-east-1** for custom domain certificates.

Use a single `aws_region` variable to control backend resources:
- **Backend region**: S3 origin + ALB + ECS + WAF + ACM for ALB

This results in two TLS terminations when using a custom CDN domain:
- **CloudFront TLS**: ACM cert in us-east-1
- **ALB TLS**: ACM cert in the ALB region

See [CLOUDFRONT.md](CLOUDFRONT.md) for detailed CloudFront setup.

## Contents

- `terraform/` - AWS infrastructure as code (ALB, ECS, WAF, S3, CloudFront)
- `scripts/` - Deployment automation scripts
  - `deploy-image.ps1/.sh` - Build and push Docker image to ECR
  - `deploy-static.ps1/.sh` - Deploy static assets to S3/CloudFront
  - `setup-terraform-backend.ps1/.sh` - One-time setup for Terraform state

## Prerequisites

- Docker installed
- AWS CLI configured
- Terraform >= 1.0
- Node.js >= 18
- ECR repository (create with `scripts/setup-ecr.ps1`)
- VPC with public/private subnets
- Route53 hosted zone

## Documentation

- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Complete step-by-step setup from scratch
- **[CLOUDFRONT.md](CLOUDFRONT.md)** - CloudFront + S3 architecture and configuration
- **[terraform/README.md](terraform/README.md)** - Terraform usage and infrastructure details
- **[terraform/RESOURCES.md](terraform/RESOURCES.md)** - Complete AWS resource list and costs

## Quick Setup Scripts

All scripts are in `scripts/` directory:

### One-Time Setup
```bash
cd deploy/scripts

# 1. Create Terraform state bucket (S3)
.\setup-terraform-backend.ps1

# 2. Create ECR repository
.\setup-ecr.ps1

# 3. Update terraform-*.tfvars with your AWS details
```

## Building and Pushing Docker Image

### 1. Build Docker Image

```bash
# From project root
docker build -t xinvestment:latest .
```

### 2. Tag for ECR

```bash
# Replace with your actual ECR repository URL
export ECR_REPO=123456789012.dkr.ecr.us-east-1.amazonaws.com/xinvestment
export IMAGE_TAG=qa-latest

docker tag xinvestment:latest $ECR_REPO:$IMAGE_TAG
```

### 3. Login to ECR

```bash
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin $ECR_REPO
```

### 4. Push to ECR

```bash
docker push $ECR_REPO:$IMAGE_TAG
```

## Deploying Infrastructure

See `terraform/README.md` for detailed instructions on deploying the AWS infrastructure.

## Quick Start - QA Environment

### Complete Deployment

```bash
# 1. Build and push API Docker image
cd deploy/scripts
.\deploy-image.ps1 -Environment qa

# 2. Deploy infrastructure (first time only)
cd ..\terraform
terraform init -backend-config=backend-qa.hcl
terraform apply -var-file=terraform-qa.tfvars

# 3. Build and deploy static assets to CloudFront
cd ..\scripts
npm run build
.\deploy-static.ps1 -Environment qa
```

### Update Static Assets Only

```bash
npm run build
cd deploy/scripts
.\deploy-static.ps1 -Environment qa
```

### Update API Only

```bash
cd deploy/scripts
.\deploy-image.ps1 -Environment qa

# ECS will automatically deploy the new image
# Or force a new deployment:
aws ecs update-service \
  --cluster xinvestment-qa-cluster \
  --service xinvestment-qa-service \
  --force-new-deployment
```

## Environment URLs

### Dev
- Static Assets (CDN): CloudFront domain (from terraform output: `cdn_url`)
- API: https://xinvestment-dev.example.com

### QA  
- Static Assets (CDN): CloudFront domain (from terraform output: `cdn_url`)
- API: https://xinvestment-qa.example.com

### Production
- Static Assets (CDN): CloudFront domain (from terraform output: `cdn_url`)
- API: https://xinvestment.example.com

**Get URLs after deployment:**
```bash
cd terraform
terraform output cdn_url
terraform output api_url
```

## CI/CD Integration

The deployment process can be automated using GitHub Actions, GitLab CI, or AWS CodePipeline.

Example workflow:
1. Code push triggers CI
2. Run tests
3. Build Docker image
4. Push to ECR
5. Update ECS task definition
6. Deploy to ECS

## Monitoring

### Application Logs
- CloudWatch Logs: `/ecs/xinvestment-{env}`
- Container Insights: ECS cluster metrics

### Security
- WAF Dashboard: AWS WAF console (request blocking, rate limiting)

### CDN Performance
- CloudFront Monitoring: Cache hit ratio, error rates, data transfer
- S3 Metrics: Storage size, request count

### Costs
- CloudFront: Data transfer and request charges
- S3: Storage and request charges  
- ECS: Fargate compute and data transfer
- ALB: Load balancer hours and LCU charges

## Rollback

```bash
# Revert to previous task definition
aws ecs update-service \
  --cluster xinvestment-qa-cluster \
  --service xinvestment-qa-service \
  --task-definition xinvestment-qa:PREVIOUS_REVISION
```

## Support

For deployment issues, contact DevOps team.
