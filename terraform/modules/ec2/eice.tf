resource "aws_security_group" "eice" {
  name        = "${var.project_name}-${var.environment}-eice-sg"
  description = "Security group for EC2 Instance Connect Endpoint"
  vpc_id      = var.vpc_id

  egress {
    description = "Allow outbound traffic to VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-eice-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_ec2_instance_connect_endpoint" "main" {
  subnet_id          = var.subnet_id
  security_group_ids = [aws_security_group.eice.id]

  tags = {
    Name        = "${var.project_name}-${var.environment}-eice"
    Environment = var.environment
    Project     = var.project_name
  }
}
