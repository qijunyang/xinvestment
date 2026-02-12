# AWS Resources List

This document lists all AWS resources that will be created by the Terraform configuration.

## Networking & Load Balancing

### Application Load Balancer (ALB)
- **Resource**: `aws_lb.main`
- **Name**: `xinvestment-{env}-alb`
- **Type**: Application Load Balancer
- **Scheme**: Internet-facing
- **Features**: HTTP/2 enabled, Cross-zone load balancing

### ALB Target Group
- **Resource**: `aws_lb_target_group.app`
- **Name**: `xinvestment-{env}-tg`
- **Protocol**: HTTP
- **Target Type**: IP (for Fargate)
- **Health Check**: `/api/health` endpoint

### ALB Listeners
1. **HTTPS Listener** (port 443)
   - **Resource**: `aws_lb_listener.https`
   - **SSL Policy**: ELBSecurityPolicy-TLS-1-2-2017-01
   - **Action**: Forward to target group

2. **HTTP Listener** (port 80)
   - **Resource**: `aws_lb_listener.http`
   - **Action**: Redirect to HTTPS (301)

## Security

### Security Groups

1. **ALB Security Group**
   - **Resource**: `aws_security_group.alb`
   - **Name**: `xinvestment-{env}-alb-sg`
   - **Ingress**: 
     - Port 443 (HTTPS) from 0.0.0.0/0
     - Port 80 (HTTP) from 0.0.0.0/0
   - **Egress**: All traffic

2. **ECS Tasks Security Group**
   - **Resource**: `aws_security_group.ecs_tasks`
   - **Name**: `xinvestment-{env}-ecs-tasks-sg`
   - **Ingress**: Container port from ALB security group only
   - **Egress**: All traffic

### WAF v2 (Web Application Firewall)
- **Resource**: `aws_wafv2_web_acl.main`
- **Name**: `xinvestment-{env}-waf`
- **Scope**: REGIONAL
- **Rules**:
  1. AWS Managed Common Rule Set
  2. AWS Managed Known Bad Inputs Rule Set
  3. Rate Limiting Rule (configurable, default 2000 req/5min)
- **Association**: Attached to ALB via `aws_wafv2_web_acl_association.main`

## SSL/TLS Certificates

### ACM Certificate
- **Resource**: `aws_acm_certificate.alb`
- **Name**: `xinvestment-{env}-alb-cert`
- **Domain**: Configurable per environment
- **Validation**: DNS validation via Route53
- **SANs**: Optional subject alternative names

### ACM Certificate Validation
- **Resource**: `aws_acm_certificate_validation.alb`
- **Method**: DNS records in Route53

## DNS (Route53)

### Route53 Records

1. **Certificate Validation Records**
   - **Resource**: `aws_route53_record.cert_validation`
   - **Type**: CNAME (for ACM validation)
   - **TTL**: 60 seconds

2. **Application A Record**
   - **Resource**: `aws_route53_record.app`
   - **Type**: A (Alias to ALB)
   - **Domain**: Configurable per environment
   - **Target**: ALB DNS name

3. **CDN A Record** (optional, if using custom domain)
   - **Resource**: `aws_route53_record.cdn`
   - **Type**: A (Alias to CloudFront)
   - **Domain**: CDN subdomain (e.g., cdn.example.com)
   - **Target**: CloudFront distribution

## Content Delivery (S3 + CloudFront)

### S3 Bucket for Static Assets
- **Resource**: `aws_s3_bucket.static_assets`
- **Name**: `xinvestment-{env}-static-assets`
- **Purpose**: Store HTML, CSS, JS bundles
- **Versioning**: Enabled via `aws_s3_bucket_versioning.static_assets`
- **Encryption**: AES256 server-side encryption
- **Public Access**: Blocked (CloudFront-only access)

### S3 Bucket Policy
- **Resource**: `aws_s3_bucket_policy.static_assets`
- **Allows**: CloudFront OAC to read objects
- **Principal**: cloudfront.amazonaws.com service
- **Action**: s3:GetObject
- **Condition**: Matches CloudFront distribution ARN

### CloudFront Distribution
- **Resource**: `aws_cloudfront_distribution.static_assets`
- **Name**: `xinvestment-{env}-cdn`
- **Origin**: S3 bucket via Origin Access Control (OAC)
- **Default Root**: `login/index.html`
- **Price Class**: Configurable (PriceClass_100/200/All)
- **Features**:
  - HTTPS redirect (viewer-protocol-policy)
  - Compression enabled
  - IPv6 enabled
  - Custom error responses (403/404 → login page)
  - AWS Managed cache policies
- **Cache Policy**: CachingOptimized (AWS managed)
- **Origin Request Policy**: CORS-S3Origin (AWS managed)

### CloudFront Origin Access Control (OAC)
- **Resource**: `aws_cloudfront_origin_access_control.static_assets`
- **Name**: `xinvestment-{env}-oac`
- **Type**: S3
- **Signing**: SigV4 (always)
- **Purpose**: Secure CloudFront → S3 access

### CloudFront Certificate (optional)
- **Variable**: `cloudfront_certificate_arn`
- **Region**: Must be in us-east-1
- **Type**: ACM certificate
- **Purpose**: Custom domain support (e.g., cdn.example.com)

## Container Orchestration (ECS)

### ECS Cluster
- **Resource**: `aws_ecs_cluster.main`
- **Name**: `xinvestment-{env}-cluster`
- **Features**: Container Insights enabled

### ECS Task Definition
- **Resource**: `aws_ecs_task_definition.app`
- **Family**: `xinvestment-{env}`
- **Launch Type**: Fargate
- **Network Mode**: awsvpc
- **CPU**: Configurable (default 512)
- **Memory**: Configurable (default 1024 MB)
- **Container**:
  - Name: xinvestment
  - Image: From ECR
  - Port: 3000 (configurable)
  - Health Check: curl to /api/health
  - Log Driver: awslogs

### ECS Service
- **Resource**: `aws_ecs_service.app`
- **Name**: `xinvestment-{env}-service`
- **Desired Count**: Configurable (default 1)
- **Launch Type**: Fargate
- **Network**: Private subnets, no public IP
- **Load Balancer**: Connected to ALB target group
- **Deployment**:
  - Max: 200%
  - Min Healthy: 100%
  - Circuit Breaker: Enabled with rollback

### Auto Scaling

1. **Auto Scaling Target**
   - **Resource**: `aws_appautoscaling_target.ecs`
   - **Min Capacity**: Configurable (default 1)
   - **Max Capacity**: Configurable (default 1)

2. **CPU-based Scaling Policy**
   - **Resource**: `aws_appautoscaling_policy.ecs_cpu`
   - **Target**: 70% CPU utilization

3. **Memory-based Scaling Policy**
   - **Resource**: `aws_appautoscaling_policy.ecs_memory`
   - **Target**: 80% Memory utilization

## IAM Roles & Policies

### ECS Task Execution Role
- **Resource**: `aws_iam_role.ecs_task_execution`
- **Name**: `xinvestment-{env}-ecs-task-execution-role`
- **Purpose**: Pull images from ECR, write logs to CloudWatch
- **Policies**: AmazonECSTaskExecutionRolePolicy

### ECS Task Role
- **Resource**: `aws_iam_role.ecs_task`
- **Name**: `xinvestment-{env}-ecs-task-role`
- **Purpose**: Runtime permissions for application
- **Policies**: Custom (add as needed)

## Logging & Monitoring

### CloudWatch Log Group
- **Resource**: `aws_cloudwatch_log_group.app`
- **Name**: `/ecs/xinvestment-{env}`
- **Retention**: Configurable (7/30/90 days by environment)

## Resource Summary by Environment

### Development (dev)
- ALB: 1
- Target Groups: 1
- Security Groups: 2
- WAF WebACL: 1
- S3 Buckets: 1 (static assets)
- CloudFront Distributions: 1
- CloudFront OAC: 1
- ECS Cluster: 1
- ECS Service: 1
- ECS Tasks: 1 (min/desired/max)
- CloudWatch Log Groups: 1
- ACM Certificates: 1 (ALB only, CloudFront uses default)
- Route53 Records: 3+ (validation + ALB A record + optional CDN)
- IAM Roles: 2
- Auto Scaling Policies: 2

### QA (qa)
Same as dev, with different resource names and configurations

### Production (prd)
Same structure with:
- Higher resource limits (CPU/Memory)
- Longer log retention
- Deletion protection enabled
- Better CloudFront price class (PriceClass_200 vs 100)
- Higher WAF rate limits

## Data Sources (Not Created, Referenced)

- VPC (existing)
- Public Subnets (existing, tagged as Tier=Public)
- Private Subnets (existing, tagged as Tier=Private)
- Route53 Hosted Zone (existing)

## Prerequisites (Must Exist)

1. **VPC** with:
   - Public subnets (tagged with Tier=Public)
   - Private subnets (tagged with Tier=Private)
   - Internet Gateway
   - NAT Gateway(s)

2. **Route53 Hosted Zone** for the domain

3. **ECR Repository** with Docker image

4. **S3 Bucket** for Terraform state (optional - for remote state storage)

## Estimated Costs (Monthly)

### Development
- ALB: ~$16
- ECS Fargate (0.25 vCPU, 0.5 GB): ~$7
- S3 Storage (static assets, ~100MB): ~$0.02
- CloudFront (minimal traffic): ~$1-3
- CloudWatch Logs (minimal): ~$2
- WAF: ~$5
- Route53: ~$0.50
- **Total**: ~$32-45/month

### QA
- ALB: ~$16
- ECS Fargate (0.5 vCPU, 1 GB): ~$15
- S3 Storage (~100MB): ~$0.02
- CloudFront (low-medium traffic): ~$3-8
- CloudWatch Logs: ~$3
- WAF: ~$5
- Route53: ~$0.50
- **Total**: ~$53-80/month

### Production
- ALB: ~$25 (higher traffic)
- ECS Fargate (1 vCPU, 2 GB): ~$30
- S3 Storage (~100MB): ~$0.02
- CloudFront (higher traffic, better price class): ~$10-25
- CloudWatch Logs: ~$5
- WAF: ~$10
- Route53: ~$0.50
- Data Transfer (reduced via CloudFront): ~$10-15
- **Total**: ~$90-140/month

**CloudFront Pricing Details:**
- Data Transfer Out (first 10 TB/month): $0.085/GB (US/Europe)
- HTTP/HTTPS Requests: $0.0075-0.01 per 10,000 requests
- Invalidations: First 1,000 paths/month free
- Price Class impacts coverage and cost (100 < 200 < All)

**Cost Savings from CloudFront:**
- Reduces ALB/ECS data transfer charges
- Edge caching reduces origin requests by 60-90%
- S3 → CloudFront transfer is FREE

*Note: Costs are estimates and will vary based on actual usage, data transfer, and request volume.*

## Tags Applied to All Resources

```
Project     = var.project_name
Environment = var.environment
ManagedBy   = Terraform
```

## Outputs

The following information will be output after deployment:
- ALB DNS name
- ALB ARN
- Application URL (HTTPS)
- ECS cluster name
- ECS service name
- CloudWatch log group name
- WAF WebACL ARN
- Security group IDs
- ACM certificate ARN
