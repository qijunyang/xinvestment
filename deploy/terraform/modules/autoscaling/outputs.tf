output "autoscaling_target_id" {
  description = "Resource ID for the ECS autoscaling target"
  value       = aws_appautoscaling_target.ecs.resource_id
}
