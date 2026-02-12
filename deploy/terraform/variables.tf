variable "aws_region" {
  description = "AWS region for backend resources (ALB + ECS + WAF + S3 origin + ACM for ALB)"
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "xinvestment"
}

variable "environment" {
  description = "Environment name (dev, qa, uat, stg, prd, dr)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where resources will be deployed"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
}

variable "route53_zone_name" {
  description = "Route53 hosted zone name"
  type        = string
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID (optional, overrides name lookup)"
  type        = string
  default     = ""
}

variable "subject_alternative_names" {
  description = "Subject Alternative Names for the ACM certificate"
  type        = list(string)
  default     = []
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 3000
}

variable "fargate_cpu" {
  description = "Fargate CPU units (1024 = 1 vCPU)"
  type        = string
  default     = "512"
}

variable "fargate_memory" {
  description = "Fargate memory in MB"
  type        = string
  default     = "1024"
}

variable "desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 0
}

variable "min_capacity" {
  description = "Minimum number of ECS tasks"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of ECS tasks"
  type        = number
  default     = 1
}

variable "ecr_repository_url" {
  description = "ECR repository URL for the container image"
  type        = string
}

variable "image_tag" {
  description = "Container image tag"
  type        = string
  default     = "latest"
}

variable "node_env" {
  description = "Node environment (development, production)"
  type        = string
  default     = "production"
}

variable "alb_deletion_protection" {
  description = "Enable deletion protection for ALB"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "waf_rate_limit" {
  description = "WAF rate limit per 5 minutes"
  type        = number
  default     = 2000
}

variable "cloudfront_price_class" {
  description = "CloudFront price class (PriceClass_All, PriceClass_200, PriceClass_100)"
  type        = string
  default     = "PriceClass_100"
}

variable "cloudfront_aliases" {
  description = "Alternate domain names (CNAMEs) for CloudFront distribution"
  type        = list(string)
  default     = []
}

variable "cloudfront_certificate_arn" {
  description = "ACM certificate ARN for CloudFront (must be in us-east-1). Leave empty to use default CloudFront certificate"
  type        = string
  default     = ""
}

