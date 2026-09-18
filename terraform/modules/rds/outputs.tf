output "db_instance_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.main.id
}

output "db_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.main.address
}

output "db_port" {
  description = "RDS PostgreSQL port"
  value       = aws_db_instance.main.port
}

output "security_group_id" {
  description = "RDS security group ID"
  value       = aws_security_group.rds.id
}
