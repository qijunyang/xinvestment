# Production Environment Configuration

aws_region  = "us-east-1"
environment = "prd"

# VPC Configuration (replace with actual VPC ID)
vpc_id = "vpc-xxxxxxxxxxxxxxxxx"

# Domain Configuration (replace with actual domain)
domain_name        = "xinvestment.example.com"
route53_zone_name  = "example.com"
subject_alternative_names = ["www.xinvestment.example.com"]

# ECS Configuration
fargate_cpu    = "1024"  # 1 vCPU
fargate_memory = "2048"  # 2 GB
desired_count  = 0
min_capacity   = 1
max_capacity   = 1

# ECR Configuration (replace with actual ECR URL)
ecr_repository_url = "123456789012.dkr.ecr.us-east-1.amazonaws.com/xinvestment"
image_tag          = "prd-latest"

# Application Configuration
node_env       = "production"
container_port = 3000

# Infrastructure Configuration
alb_deletion_protection = true
log_retention_days      = 90

# WAF Configuration
waf_rate_limit = 5000

# CloudFront Configuration
cloudfront_price_class     = "PriceClass_200"  # Better global coverage for production
cloudfront_aliases         = []  # Example: ["cdn.example.com"]
cloudfront_certificate_arn = ""  # Add ACM cert ARN (must be in us-east-1)
