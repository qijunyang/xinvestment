variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, qa, uat, stg, prd)"
  type        = string
}

variable "cloudfront_price_class" {
  description = "CloudFront price class"
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of the ALB for the API origin"
  type        = string
}

variable "alb_id" {
  description = "ID of the ALB for origin identification"
  type        = string
}

variable "default_root_object" {
  description = "Default root object for CloudFront"
  type        = string
  default     = "login/index.html"
}
