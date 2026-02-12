variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, qa, uat, stg, prd)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where resources will be deployed"
  type        = string
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the ALB"
  type        = list(string)
}

variable "alb_deletion_protection" {
  description = "Enable deletion protection for ALB"
  type        = bool
}

variable "cloudfront_prefix_list_id" {
  description = "CloudFront origin-facing prefix list ID"
  type        = string
}
