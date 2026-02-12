# Xinvestment Terraform Infrastructure

This directory contains Terraform configuration for deploying the Xinvestment application to AWS.

## Architecture

The infrastructure includes:

- **Route53**: DNS management
- **ACM**: SSL/TLS certificates
- **Application Load Balancer (ALB)**: Load balancing with HTTPS
- **WAF v2**: Web application firewall with AWS managed rules
- **ECS Fargate**: Container orchestration
- **CloudWatch**: Logging and monitoring
- **Security Groups**: Network security
- **Auto Scaling**: CPU and memory-based scaling

## Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform >= 1.0 installed
3. VPC with public and private subnets
4. ECR repository created with Docker image
5. Route53 hosted zone
6. S3 bucket for Terraform state (optional, run `setup-terraform-backend` script)

## Directory Structure

```
terraform/
├── main.tf                  # Main infrastructure configuration
├── variables.tf             # Variable declarations
├── outputs.tf              # Output values
├── terraform-dev.tfvars    # Dev environment variables
├── terraform-qa.tfvars     # QA environment variables
├── terraform-prd.tfvars    # Production environment variables
├── backend-dev.hcl         # Dev backend configuration
├── backend-qa.hcl          # QA backend configuration
├── backend-prd.hcl         # Production backend configuration
└── README.md               # This file
```

## Usage

### 1. Update Environment Variables

Edit the appropriate `terraform-<env>.tfvars` file with your actual values:

- `vpc_id`: Your VPC ID
- `domain_name`: Your domain name
- `route53_zone_name`: Your Route53 hosted zone name (optional if using ID)
- `route53_zone_id`: Your Route53 hosted zone ID (optional, overrides name lookup)
- `ecr_repository_url`: Your ECR repository URL
- `aws_region`: Region for S3 origin + ALB + ECS + WAF + ALB ACM cert

**CloudFront region note**:
- CloudFront custom domain cert must be in **us-east-1** (fixed)

**TLS note**:
- CloudFront custom domain cert must be in **us-east-1**
- ALB cert must be in the **backend_region**

### 2. Initialize Terraform

```bash
# For QA environment
terraform init -backend-config=backend-qa.hcl

# For Dev environment
terraform init -backend-config=backend-dev.hcl

# For Production environment
terraform init -backend-config=backend-prd.hcl
```

### 3. Plan Infrastructure Changes

```bash
# For QA environment
terraform plan -var-file=terraform-qa.tfvars

# For Dev environment
terraform plan -var-file=terraform-dev.tfvars

# For Production environment
terraform plan -var-file=terraform-prd.tfvars
```

### 4. Apply Infrastructure Changes

```bash
# For QA environment
terraform apply -var-file=terraform-qa.tfvars

# For Dev environment
terraform apply -var-file=terraform-dev.tfvars

# For Production environment
terraform apply -var-file=terraform-prd.tfvars
```

### 5. View Outputs

```bash
terraform output
```

### 6. Destroy Infrastructure (if needed)

```bash
# For QA environment
terraform destroy -var-file=terraform-qa.tfvars
```

## Environment-Specific Configurations

### Dev Environment
- Minimal resources (256 CPU, 512 MB RAM)
- Lower WAF rate limits
- 7-day log retention
- No deletion protection

### QA Environment
- Medium resources (512 CPU, 1024 MB RAM)
- Standard WAF rate limits
- 30-day log retention
- No deletion protection

### Production Environment
- Higher resources (1024 CPU, 2048 MB RAM)
- Higher WAF rate limits
- 90-day log retention
- Deletion protection enabled
- Additional subject alternative names

## Resource Naming Convention

All resources follow the naming pattern: `{project_name}-{environment}-{resource_type}`

Example: `xinvestment-qa-alb`

## Security Features

1. **WAF Protection**:
   - AWS Managed Common Rule Set
   - AWS Managed Known Bad Inputs Rule Set
   - Rate limiting per IP

2. **Security Groups**:
   - ALB: Only allows 80 and 443 from internet
   - ECS Tasks: Only allows traffic from ALB on container port

3. **TLS/SSL**:
   - ACM certificates with automatic DNS validation
   - TLS 1.2 minimum policy on ALB
   - HTTP to HTTPS redirect

4. **Network Isolation**:
   - ECS tasks run in private subnets
   - ALB in public subnets

## Monitoring

- CloudWatch Container Insights enabled on ECS cluster
- Application logs sent to CloudWatch Logs
- WAF metrics available in CloudWatch

## Auto Scaling

- Target CPU utilization: 70%
- Target Memory utilization: 80%
- Configuration set to 1/1/1 (min/desired/max) but can be adjusted

## Health Checks

- ALB health check: `/api/health` endpoint
- Container health check: curl command to localhost health endpoint
- Health check interval: 30 seconds

## Costs

Estimated monthly costs for each environment (approximate):

- **Dev**: ~$30-40/month
- **QA**: ~$50-70/month
- **Production**: ~$80-120/month

Actual costs depend on usage, data transfer, and CloudWatch metrics.

## Troubleshooting

### Certificate Validation Stuck

If ACM certificate validation is taking too long:

1. Check Route53 records were created correctly
2. Verify the hosted zone is correct
3. DNS propagation can take up to 30 minutes

### ECS Tasks Not Starting

1. Check CloudWatch logs: `/ecs/xinvestment-{env}`
2. Verify ECR image exists and is accessible
3. Check security group rules
4. Verify IAM roles have correct permissions

### ALB Health Checks Failing

1. Verify `/api/health` endpoint is responding
2. Check security group allows ALB to ECS communication
3. Review ECS task logs

## Additional Configuration

Create S3 bucket for state management (one-time setup):

**Option 1: Use the setup script**
```bash
cd ../scripts
./setup-terraform-backend.ps1   # PowerShell
# or
./setup-terraform-backend.sh    # Bash
```

**Option 2: Manual creation**
```bash
# Create S3 bucket
aws s3 mb s3://xinvestment-terraform-state --region us-east-1
aws s3api put-bucket-versioning \
  --bucket xinvestment-terraform-state \
  --versioning-configuration Status=Enabled
```

**Note**: State locking (DynamoDB) is disabled for simplicity. This is fine for solo/demo work.

## Support

For issues or questions, contact the DevOps team.
