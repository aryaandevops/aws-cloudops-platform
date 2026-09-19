output "security_group_id" {
  description = "EC2 security group ID"
  value       = aws_security_group.ec2.id
}
