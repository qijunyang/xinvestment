# Dev Environment Configuration

aws_region  = "us-east-1"
environment = "dev"

# VPC Configuration (replace with actual VPC ID)
vpc_id = "vpc-xxxxxxxxxxxxxxxxx"

# Domain Configuration (replace with actual domain)
domain_name        = "xinvestment-dev.example.com"
route53_zone_name  = "example.com"
subject_alternative_names = []

# ECS Configuration
fargate_cpu    = "256"   # 0.25 vCPU
fargate_memory = "512"   # 0.5 GB
desired_count  = 1
min_capacity   = 1
max_capacity   = 1

# ECR Configuration (replace with actual ECR URL)
ecr_repository_url = "123456789012.dkr.ecr.us-east-1.amazonaws.com/xinvestment"
image_tag          = "dev-latest"

# Application Configuration
node_env       = "development"
container_port = 3000

# Infrastructure Configuration
alb_deletion_protection = false
log_retention_days      = 7

# WAF Configuration
waf_rate_limit = 1000

# CloudFront Configuration
cloudfront_price_class     = "PriceClass_100"
cloudfront_aliases         = []  # Use default CloudFront domain
cloudfront_certificate_arn = ""  # Use default CloudFront certificate
