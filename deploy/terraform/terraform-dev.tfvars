# Dev Environment Configuration

aws_region  = "us-east-2"
environment = "dev"

# VPC Configuration (replace with actual VPC ID)
vpc_id = "vpc-0b7672e5281122ff8"

# Domain Configuration (replace with actual domain)
domain_name        = "xinvestment-dev.xinvestment.com"
route53_zone_name  = "xinvestment.com"
route53_zone_id    = "Z07223402FNDO6DI1G8NP"
subject_alternative_names = []

# ECS Configuration
fargate_cpu    = "256"   # 0.25 vCPU
fargate_memory = "512"   # 0.5 GB
desired_count  = 0
min_capacity   = 0
max_capacity   = 1

# ECR Configuration (replace with actual ECR URL)
ecr_repository_url = "411119517943.dkr.ecr.us-east-2.amazonaws.com/xinvestment"
image_tag          = "dev-latest"

# Application Configuration
node_env       = "dev"
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
