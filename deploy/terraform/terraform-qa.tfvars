# QA Environment Configuration

aws_region  = "us-east-1"
environment = "qa"

# VPC Configuration (replace with actual VPC ID)
vpc_id = "vpc-xxxxxxxxxxxxxxxxx"

# Domain Configuration (replace with actual domain)
domain_name        = "xinvestment-qa.example.com"
route53_zone_name  = "example.com"
subject_alternative_names = []

# ECS Configuration
fargate_cpu    = "512"   # 0.5 vCPU
fargate_memory = "1024"  # 1 GB
desired_count  = 1
min_capacity   = 1
max_capacity   = 1

# ECR Configuration (replace with actual ECR URL)
ecr_repository_url = "123456789012.dkr.ecr.us-east-1.amazonaws.com/xinvestment"
image_tag          = "qa-latest"

# Application Configuration
node_env       = "production"
container_port = 3000

# Infrastructure Configuration
alb_deletion_protection = false
log_retention_days      = 30

# WAF Configuration
waf_rate_limit = 2000

# CloudFront Configuration
cloudfront_price_class     = "PriceClass_100"
cloudfront_aliases         = []  # Example: ["cdn-qa.example.com"]
cloudfront_certificate_arn = ""  # Add ACM cert ARN if using custom domain
