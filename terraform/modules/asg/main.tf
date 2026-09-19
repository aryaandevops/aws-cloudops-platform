resource "aws_launch_template" "app" {

  lifecycle {
    ignore_changes = [
      user_data
    ]
  }

  name_prefix   = "${var.project_name}-${var.environment}-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  iam_instance_profile {
    name = var.instance_profile_name
  }

  vpc_security_group_ids = [
    var.ec2_security_group_id
  ]

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "${var.project_name}-${var.environment}-asg"
      Environment = var.environment
      Project     = var.project_name
      Role        = "Application"
    }
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e

    apt-get update -y
    apt-get install -y docker.io curl unzip

    curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
    unzip -q /tmp/awscliv2.zip -d /tmp
    /tmp/aws/install

    systemctl enable docker
    systemctl start docker

    usermod -aG docker ubuntu || true

    REGION="us-east-1"
    ECR_REGISTRY="012646746635.dkr.ecr.us-east-1.amazonaws.com"
    IMAGE="$ECR_REGISTRY/aws-cloudops-app:${var.app_image_tag}"

    DB_HOST=$(aws ssm get-parameter \
      --name "/cloudops/dev/db-host" \
      --region "$REGION" \
      --query "Parameter.Value" \
      --output text)

    DB_PORT=$(aws ssm get-parameter \
      --name "/cloudops/dev/db-port" \
      --region "$REGION" \
      --query "Parameter.Value" \
      --output text)

    DB_NAME=$(aws ssm get-parameter \
      --name "/cloudops/dev/db-name" \
      --region "$REGION" \
      --query "Parameter.Value" \
      --output text)

    DB_USER=$(aws ssm get-parameter \
      --name "/cloudops/dev/db-user" \
      --region "$REGION" \
      --query "Parameter.Value" \
      --output text)

    DB_PASSWORD=$(aws ssm get-parameter \
      --name "/cloudops/dev/db-password" \
      --with-decryption \
      --region "$REGION" \
      --query "Parameter.Value" \
      --output text)

    aws ecr get-login-password --region "$REGION" | \
      docker login --username AWS --password-stdin "$ECR_REGISTRY"

    docker pull "$IMAGE"

    docker run -d \
      --name aws-cloudops-app \
      --restart unless-stopped \
      -p 80:5000 \
      -e DB_HOST="$DB_HOST" \
      -e DB_PORT="$DB_PORT" \
      -e DB_NAME="$DB_NAME" \
      -e DB_USER="$DB_USER" \
      -e DB_PASSWORD="$DB_PASSWORD" \
      "$IMAGE"
  EOF
  )
}

resource "aws_autoscaling_group" "app" {
  name = "${var.project_name}-${var.environment}-asg"

  min_size         = 1
  desired_capacity = 1
  max_size         = 2

  vpc_zone_identifier = var.subnet_ids

  target_group_arns = [
    var.target_group_arn
  ]

  health_check_type         = "ELB"
  health_check_grace_period = 120

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  lifecycle {
    ignore_changes = [
      launch_template[0].version
    ]
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-asg"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }
}
