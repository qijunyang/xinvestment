output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer (private - not directly accessible)"
  value       = module.alb.alb_dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = module.alb.alb_zone_id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = module.alb.alb_arn
}

output "alb_security_group_id" {
  description = "Security group ID for ALB"
  value       = module.alb.alb_security_group_id
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs_service.ecs_cluster_name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = module.ecs_service.ecs_cluster_arn
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.ecs_service.ecs_service_name
}

output "ecs_task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = module.ecs_service.ecs_task_definition_arn
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = module.ecs_service.cloudwatch_log_group_name
}

output "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL"
  value       = module.waf.web_acl_arn
}

output "waf_web_acl_id" {
  description = "ID of the WAF Web ACL"
  value       = module.waf.web_acl_id
}

output "ecs_security_group_id" {
  description = "Security group ID for ECS tasks"
  value       = module.ecs_service.ecs_security_group_id
}

output "s3_static_assets_bucket" {
  description = "S3 bucket name for static assets"
  value       = module.static_cdn.s3_static_assets_bucket
}

output "s3_static_assets_bucket_arn" {
  description = "ARN of the S3 bucket for static assets"
  value       = module.static_cdn.s3_static_assets_bucket_arn
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = module.static_cdn.cloudfront_distribution_id
}

output "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution"
  value       = module.static_cdn.cloudfront_distribution_arn
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name (use this to access the application)"
  value       = module.static_cdn.cloudfront_domain_name
}

output "application_url" {
  description = "Application URL (CloudFront - public access point)"
  value       = module.static_cdn.cdn_url
}

output "cdn_url" {
  description = "CDN URL for static assets"
  value       = module.static_cdn.cdn_url
}

