resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-${var.environment}-ec2-sg"
  description = "Security group for CloudOps EC2"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

ingress {
  description     = "HTTP from ALB"
  from_port       = 80
  to_port         = 80
  protocol        = "tcp"
  security_groups = [var.alb_security_group_id]
}

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-ec2-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

resource "aws_instance" "app" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  associate_public_ip_address = true

  iam_instance_profile = var.instance_profile_name

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

user_data = <<-EOF
  #!/bin/bash
  set -e

  apt-get update -y

  # Install Docker
  apt-get install -y docker.io

  systemctl enable docker
  systemctl start docker

  usermod -aG docker ubuntu

  # Install and start AWS Systems Manager Agent
  snap install amazon-ssm-agent --classic
  systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent
  systemctl start snap.amazon-ssm-agent.amazon-ssm-agent

  echo "CloudOps EC2 initialized successfully" > /var/www-cloudops.txt
  EOF

  tags = {
    Name        = "${var.project_name}-${var.environment}-app"
    Environment = var.environment
    Project     = var.project_name
    Role        = "Application"
  }
}
