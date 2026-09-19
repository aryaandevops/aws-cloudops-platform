output "monitoring_instance_id" {
  description = "Monitoring EC2 instance ID"
  value       = aws_instance.monitoring.id
}

output "monitoring_public_ip" {
  description = "Monitoring EC2 public IP"
  value       = aws_instance.monitoring.public_ip
}

output "monitoring_security_group_id" {
  description = "Monitoring security group ID"
  value       = aws_security_group.monitoring.id
}
