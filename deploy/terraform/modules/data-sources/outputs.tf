output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = data.aws_subnets.public.ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = data.aws_subnets.private.ids
}

output "cloudfront_prefix_list_id" {
  description = "CloudFront origin-facing prefix list ID"
  value       = data.aws_ec2_managed_prefix_list.cloudfront.id
}
