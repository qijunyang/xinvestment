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

variable "fargate_cpu" {
  description = "Fargate CPU units (1024 = 1 vCPU)"
  type        = string
}

variable "fargate_memory" {
  description = "Fargate memory in MB"
  type        = string
}

variable "desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for ECS tasks"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID for ALB"
  type        = string
}

variable "target_group_arn" {
  description = "Target group ARN for ECS service"
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
}

variable "ecr_repository_url" {
  description = "ECR repository URL for the container image"
  type        = string
}

variable "image_tag" {
  description = "Container image tag"
  type        = string
}

variable "node_env" {
  description = "Node environment (development, production)"
  type        = string
}
