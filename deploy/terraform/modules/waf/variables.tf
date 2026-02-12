variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, qa, uat, stg, prd)"
  type        = string
}

variable "waf_rate_limit" {
  description = "WAF rate limit per 5 minutes"
  type        = number
}

variable "alb_arn" {
  description = "ALB ARN to associate the WAF with"
  type        = string
}
