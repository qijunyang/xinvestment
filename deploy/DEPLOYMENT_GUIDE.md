# Complete Deployment Setup Guide

This guide walks through setting up the Xinvestment application from scratch in AWS.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                         Users                            │
└─────────────┬──────────────────────┬────────────────────┘
              │                       │
              │                       │
         Static Assets           API Requests
         (HTML, CSS, JS)         (/api/*)
              │                       │
              ▼                       ▼
      ┌──────────────┐         ┌──────────┐
      │  CloudFront  │         │   ALB    │
      │     (CDN)    │         │  (HTTPS) │
      └──────┬───────┘         └────┬─────┘
             │                      │
             ▼                      ▼
      ┌─────────────┐        ┌──────────────┐
      │  S3 Bucket  │        │ ECS Fargate  │
      │   (Static)  │        │   (Express)  │
      └─────────────┘        └──────────────┘
             │                      │
             │                      │
         Webpack Bundles      API Endpoints
         JS, CSS, HTML        Authentication
                              Business Logic
```

## Prerequisites

### Required Tools
- [x] AWS CLI installed and configured
- [x] Terraform >= 1.0
- [x] Docker Desktop
- [x] Node.js >= 18
- [x] Git

### AWS Account Requirements
- [x] AWS account with appropriate permissions
- [x] VPC with public and private subnets
- [x] Route53 hosted zone for your domain
- [x] AWS credentials configured locally

### Verify AWS Access
```bash
aws sts get-caller-identity
aws ec2 describe-vpcs
aws route53 list-hosted-zones
```

## Step-by-Step Setup

### 1. One-Time AWS Infrastructure Setup

#### A. Create Terraform State Bucket
```bash
cd deploy/scripts
.\setup-terraform-backend.ps1

# Verify
aws s3 ls | findstr terraform-state
```

#### B. Create ECR Repository
```bash
.\setup-ecr.ps1

# Copy the repository URI output, e.g.:
# 123456789012.dkr.ecr.us-east-1.amazonaws.com/xinvestment
```

#### C. Update Terraform Variables

Edit `deploy/terraform/terraform-qa.tfvars`:

```hcl
# Update these values:
vpc_id            = "vpc-xxxxxxxxxxxxx"     # Your VPC ID
domain_name       = "xinvestment-qa.yourdomain.com"
route53_zone_name = "yourdomain.com"
ecr_repository_url = "123456789012.dkr.ecr.us-east-1.amazonaws.com/xinvestment"
```

Find your VPC ID:
```bash
aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value|[0]]' --output table
```

### 2. Build and Deploy Application

#### A. Build Static Assets
```bash
# From project root
npm install
npm run build

# Verify dist/ folder created
ls dist/
```

#### B. Build and Push Docker Image
```bash
cd deploy/scripts
.\deploy-image.ps1 -Environment qa

# This will:
# - Build Docker image
# - Tag for ECR
# - Login to ECR
# - Push image
```

#### C. Deploy Infrastructure with Terraform
```bash
cd ..\terraform

# Initialize Terraform
terraform init -backend-config=backend-qa.hcl

# Review changes
terraform plan -var-file=terraform-qa.tfvars

# Deploy (takes 5-10 minutes)
terraform apply -var-file=terraform-qa.tfvars
```

Resources created:
- ALB + Target Group + Listeners
- WAF WebACL
- ECS Cluster + Service + Task Definition
- S3 Bucket (static assets)
- CloudFront Distribution
- Security Groups
- IAM Roles
- CloudWatch Log Groups
- Route53 Records
- ACM Certificate

#### D. Deploy Static Assets to CloudFront
```bash
cd ..\..\scripts
.\deploy-static.ps1 -Environment qa

# This will:
# - Upload dist/ to S3
# - Create CloudFront invalidation
# - Output CDN URL
```

#### E. Get URLs
```bash
cd ..\terraform
terraform output

# Important outputs:
# - cdn_url: CloudFront distribution URL
# - api_url: API endpoint URL
# - application_url: Main application URL
```

### 3. Verify Deployment

#### A. Check CloudFront
```bash
# Get CloudFront URL
$CDN_URL = terraform output -raw cdn_url
Write-Host $CDN_URL

# Test in browser or curl
curl $CDN_URL
```

#### B. Check API
```bash
# Get API URL
$API_URL = terraform output -raw api_url
Write-Host $API_URL

# Test health endpoint
curl "$API_URL/api/health"
# Should return: {"status":"healthy"}
```

#### C. Check ECS Service
```bash
aws ecs describe-services \
  --cluster xinvestment-qa-cluster \
  --services xinvestment-qa-service \
  --query 'services[0].{Status:status,Running:runningCount,Desired:desiredCount}'
```

#### D. Check Logs
```bash
# Stream ECS logs
aws logs tail /ecs/xinvestment-qa --follow
```

### 4. Update Application Code (Future Deployments)

#### Static Assets Only
If you only changed frontend code:
```bash
npm run build
cd deploy/scripts
.\deploy-static.ps1 -Environment qa
```

#### API Only
If you only changed backend code:
```bash
cd deploy/scripts
.\deploy-image.ps1 -Environment qa

# Force ECS to redeploy
aws ecs update-service \
  --cluster xinvestment-qa-cluster \
  --service xinvestment-qa-service \
  --force-new-deployment
```

#### Both Static and API
```bash
# Build static
npm run build

# Deploy static
cd deploy/scripts
.\deploy-static.ps1 -Environment qa

# Deploy API
.\deploy-image.ps1 -Environment qa
```

## Environment-Specific Setup

### Development Environment
```bash
# Follow same steps but use terraform-dev.tfvars
terraform apply -var-file=terraform-dev.tfvars
.\deploy-image.ps1 -Environment dev
.\deploy-static.ps1 -Environment dev
```

### Production Environment
```bash
# Additional considerations for production:
# 1. Use terraform-prd.tfvars
# 2. Enable ALB deletion protection
# 3. Use custom domain for CloudFront
# 4. Create ACM certificate in us-east-1 for CloudFront
# 5. Set longer log retention (90 days)

terraform apply -var-file=terraform-prd.tfvars
.\deploy-image.ps1 -Environment prd v1.0.0  # Use version tags
.\deploy-static.ps1 -Environment prd
```

## Troubleshooting

### Terraform Apply Fails

**Certificate validation stuck:**
```bash
# Check Route53 records
aws route53 list-resource-record-sets \
  --hosted-zone-id Z1234567890ABC \
  --query "ResourceRecordSets[?Type=='CNAME']"

# DNS can take up to 30 minutes to propagate
```

**ECS tasks failing to start:**
```bash
# Check task logs
aws logs tail /ecs/xinvestment-qa --follow

# Check task definition
aws ecs describe-task-definition \
  --task-definition xinvestment-qa \
  --query 'taskDefinition.containerDefinitions[0]'
```

### Static Assets Not Loading

**CloudFront shows 403:**
```bash
# Check S3 bucket policy
aws s3api get-bucket-policy \
  --bucket xinvestment-qa-static-assets

# Check CloudFront OAC configuration
aws cloudfront get-distribution \
  --id E1234567890ABC \
  --query 'Distribution.DistributionConfig.Origins'
```

**Assets not updating:**
```bash
# Check invalidation status
aws cloudfront list-invalidations \
  --distribution-id E1234567890ABC

# Create manual invalidation
aws cloudfront create-invalidation \
  --distribution-id E1234567890ABC \
  --paths "/*"
```

### API Not Responding

**Check ALB health:**
```bash
# Target health
aws elbv2 describe-target-health \
  --target-group-arn arn:aws:elasticloadbalancing:...:targetgroup/xinvestment-qa-tg/...

# Should show "healthy"
```

**Check ECS service:**
```bash
aws ecs describe-services \
  --cluster xinvestment-qa-cluster \
  --services xinvestment-qa-service \
  --query 'services[0].events[0:5]'
```

## Cost Monitoring

### View Current Month Costs
```bash
aws ce get-cost-and-usage \
  --time-period Start=2026-02-01,End=2026-02-28 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=SERVICE

# Key services to monitor:
# - EC2 (Fargate)
# - CloudFront
# - S3
# - ElasticLoadBalancing
```

### Set Up Cost Alerts
1. AWS Console → Billing → Budgets
2. Create budget for $100/month
3. Set alert at 80% threshold

## Cleanup (Tear Down)

To remove all infrastructure:

```bash
cd deploy/terraform

# WARNING: This will delete everything!
terraform destroy -var-file=terraform-qa.tfvars

# Manually delete (not managed by Terraform):
# - ECR repository and images
# - S3 terraform state bucket
# - CloudWatch log data (after retention period)
```

## Security Best Practices

1. **Secrets Management**
   - Never commit AWS credentials
   - Use AWS Secrets Manager for sensitive data
   - Rotate credentials regularly

2. **Network Security**
   - ECS tasks in private subnets ✓
   - ALB in public subnets ✓
   - Security groups restrict traffic ✓

3. **Access Control**
   - Use IAM roles, not access keys
   - Principle of least privilege
   - Enable MFA on AWS account

4. **Monitoring**
   - Enable CloudWatch Container Insights ✓
   - Set up CloudWatch Alarms
   - Monitor WAF metrics

## Next Steps

- [ ] Set up CI/CD pipeline (GitHub Actions, GitLab CI)
- [ ] Add CloudWatch alarms for errors
- [ ] Configure custom domain for CloudFront
- [ ] Add Redis/ElastiCache for session storage (if scaling > 1)
- [ ] Set up automated backups
- [ ] Enable AWS CloudTrail for audit
- [ ] Configure HTTPS for custom domains

## Support

For issues:
1. Check CloudWatch Logs: `/ecs/xinvestment-{env}`
2. Review Terraform outputs
3. Verify AWS resource state in console
4. See `deploy/CLOUDFRONT.md` for CDN-specific issues

## Reference

- Terraform Config: `deploy/terraform/main.tf`
- CloudFront Guide: `deploy/CLOUDFRONT.md`
- Docker Guide: `DOCKER.md`
- Build Guide: `BUILD.md`
