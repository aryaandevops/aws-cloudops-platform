variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
}

variable "subnet_id" {
  description = "Public subnet for monitoring instance"
  type        = string
}

variable "app_security_group_id" {
  description = "Application EC2 security group ID"
  type        = string
}


variable "instance_type" {
  description = "Monitoring instance type"
  type        = string
  default     = "t3.micro"
}
