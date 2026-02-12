# Xinvestment Deployment Guide

**IMPORTANT: Always run deployment scripts from the `deploy/` folder!**

This directory contains deployment configurations and scripts for the Xinvestment application.

## Quick Start

```powershell
cd deploy
.\scripts\deploy-pipeline.ps1 -Environment dev
```

This runs the complete deployment pipeline:
1. Setup Terraform backend S3 bucket
2. Setup ECR repository
3. Build and push Docker image
4. Deploy AWS infrastructure
5. Deploy static assets to S3/CloudFront

## Architecture

The application uses a hybrid architecture:
- **CloudFront + S3**: Serves static assets (HTML, CSS, JS bundles)
- **ALB + ECS Fargate**: Serves API endpoints
- **WAF**: Web Application Firewall on ALB
- **Route53**: DNS management

### Multi-Region Note

- **CloudFront**: Fixed to `us-east-1` (ACM cert requirement)
- **Backend Resources**: Single configurable region (e.g., `us-east-2`)
  - ALB + ECS + WAF + ACM (backend) + S3 origin bucket

See [CLOUDFRONT.md](CLOUDFRONT.md) for detailed architecture.

## Directory Structure

```
deploy/
├── README.md                              # This file
├── DEPLOYMENT_GUIDE.md                    # Complete setup reference
├── CLOUDFRONT.md                          # CloudFront architecture
├── iam-policy-xinvestment-deployment.json # IAM permissions required
├── scripts/                               # Deployment automation
│   ├── deploy-pipeline.ps1               # Full automated pipeline
│   ├── deploy-image.ps1                  # Docker build & ECR push
│   ├── deploy-static.ps1                 # S3 + CloudFront deploy
│   ├── setup-terraform-backend.ps1       # Terraform state setup
│   ├── setup-ecr.ps1                     # ECR repository setup
│   └── destroy-pipeline.ps1              # Teardown resources
└── terraform/                             # AWS infrastructure
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    ├── terraform-dev.tfvars               # Dev environment config
    ├── terraform-qa.tfvars                # QA environment config
    └── backend-*.hcl                      # State backend configs
```

## Prerequisites

- [x] Docker Desktop
- [x] AWS CLI configured
- [x] Terraform >= 1.0
- [x] Node.js >= 18
- [x] Git
- [x] PowerShell 5.1+ (Windows) or Bash (Mac/Linux)
- [x] AWS account with appropriate IAM permissions
- [x] VPC with subnets (existing, not created by this)
- [x] Route53 hosted zone

## IAM Permissions

Before deployment, your AWS IAM user needs these permissions:
1. S3 (Terraform state + static assets)
2. ECR (repository + image management)
3. ECS (cluster + service + task definition)
4. ALB (load balancer + listeners + target groups)
5. CloudFront (distributions)
6. Route53 (DNS records)
7. WAF (web ACL)
8. ACM (certificates)
9. CloudWatch (logs)
10. IAM (roles + policies for ECS)

See [iam-policy-xinvestment-deployment.json](iam-policy-xinvestment-deployment.json) for the complete policy.

## Deployment Scripts

### Full Pipeline (Recommended)

```powershell
cd deploy
.\scripts\deploy-pipeline.ps1 -Environment dev
```

Automatically runs all steps in sequence. Idempotent (safe to re-run).

### Individual Scripts

If you prefer step-by-step control:

```powershell
cd deploy

# Step 1: Setup Terraform backend
.\scripts\setup-terraform-backend.ps1

# Step 2: Setup ECR repository
.\scripts\setup-ecr.ps1 -Region us-east-2

# Step 3: Build and push Docker image
.\scripts\deploy-image.ps1 -Environment dev

# Step 4: Build frontend assets (from project root, then back to deploy)
cd ..
npm run build
cd deploy

# Step 5: Deploy AWS infrastructure (from terraform directory)
cd terraform
terraform init -backend-config=backend-dev.hcl
terraform plan -var-file=terraform-dev.tfvars
terraform apply -var-file=terraform-dev.tfvars

# Step 6: Deploy static assets
cd ..
.\scripts\deploy-static.ps1 -Environment dev
```

### Cleanup

```powershell
cd deploy
.\scripts\destroy-pipeline.ps1 -Environment dev
```

**WARNING**: This deletes all AWS resources for that environment!

## Configuration

Each environment needs two files in `deploy/terraform/`:

1. **terraform-{env}.tfvars** - Infrastructure variables
   ```hcl
   aws_region         = "us-east-2"
   domain_name        = "xinvestment-dev.xinvestment.com"
   ecr_repository_url = "411119517943.dkr.ecr.us-east-2.amazonaws.com/xinvestment"
   vpc_id             = "vpc-0b7672e5281122ff8"
   route53_zone_id    = "Z07223402FNDO6DI1G8NP"
   ```

2. **backend-{env}.hcl** - Terraform state backend
   ```hcl
   bucket = "xinvestment-terraform-state"
   region = "us-east-2"
   key    = "dev/terraform.tfstate"
   ```

## Environment Variables

AWS credentials should be configured via AWS CLI:
```powershell
aws configure --profile default
# Or set directly:
$env:AWS_ACCESS_KEY_ID = "your-key"
$env:AWS_SECRET_ACCESS_KEY = "your-secret"
```

## Post-Deployment

After deployment completes, get your URLs:

```powershell
cd deploy\terraform

# API endpoint
terraform output api_url

# CloudFront CDN URL
terraform output cdn_url

# ALB DNS name (for testing)
terraform output alb_dns_name
```

## Monitoring

View application logs:

```powershell
# Real-time logs
aws logs tail /ecs/xinvestment-dev --follow

# Specific time range
aws logs get-log-events \
  --log-group-name /ecs/xinvestment-dev \
  --log-stream-name ecs/xinvestment-dev/container-name \
  --start-time 1000 \
  --limit 100
```

## Troubleshooting

### IAM Permission Denied

Error: `User is not authorized to perform: s3:GetBucketPolicy`

**Solution**: Update IAM policy. Copy [iam-policy-xinvestment-deployment.json](iam-policy-xinvestment-deployment.json) to AWS IAM Console.

### ECR Login Failed

Error: `Your authorization token has expired`

**Solution**: Re-authenticate with ECR:
```powershell
cd deploy
.\scripts\deploy-image.ps1 -Environment dev
```

### Terraform State Locked

Error: `Error: Error acquiring the lock`

**Solution**: Release lock (be cautious):
```powershell
cd deploy\terraform
terraform force-unlock LOCK_ID
```

### Docker Build Fails

Error: `npm: command not found` in Docker

**Solution**: Build locally first:
```powershell
# From project root
npm run build

# Then run deployment
cd deploy
.\scripts\deploy-image.ps1 -Environment dev
```

## Contributing

When adding new deployment steps:

1. Update the script to run from the `deploy/` folder
2. Use `$DeployDir` to reference the deploy directory
3. Add validation to check required paths exist
4. Document the new step in this README
5. Test with `-Environment dev` first

## References

- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Complete reference for all scripts
- **[CLOUDFRONT.md](CLOUDFRONT.md)** - CloudFront + S3 details
- **[terraform/README.md](terraform/README.md)** - Terraform configuration
- **[iam-policy-xinvestment-deployment.json](iam-policy-xinvestment-deployment.json)** - IAM permissions

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
