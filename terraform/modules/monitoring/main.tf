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

resource "aws_security_group" "monitoring" {
  name        = "${var.project_name}-${var.environment}-monitoring-sg"
  description = "Security group for Prometheus and Grafana"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Prometheus from application instances"
    from_port       = 9100
    to_port         = 9100
    protocol        = "tcp"
    security_groups = [var.app_security_group_id]
  }

  ingress {
    description     = "Grafana from VPC"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  ingress {
    description = "Grafana from admin IP"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["152.58.32.101/32"]
  }

  ingress {
    description     = "Prometheus from VPC"
    from_port       = 9090
    to_port         = 9090
    protocol        = "tcp"
    cidr_blocks     = [var.vpc_cidr]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-monitoring-sg"
    Environment = var.environment
    Project     = var.project_name
    Role        = "Monitoring"
  }
}

resource "aws_instance" "monitoring" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  iam_instance_profile = aws_iam_instance_profile.monitoring.name

  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.monitoring.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = <<-USERDATA
    #!/bin/bash
    set -e

    apt-get update -y
    apt-get install -y docker.io curl

    systemctl enable docker
    systemctl start docker

    mkdir -p /opt/monitoring/prometheus
    mkdir -p /opt/monitoring/grafana

    cat > /opt/monitoring/prometheus/prometheus.yml <<'PROM'
    global:
      scrape_interval: 15s

    scrape_configs:
      - job_name: "node-exporter"
        ec2_sd_configs:
          - region: us-east-1
            port: 9100
            filters:
              - name: "tag:Project"
                values: ["aws-cloudops"]
              - name: "tag:Role"
                values: ["Application"]
    PROM

    docker network create monitoring || true

    docker run -d \
      --name prometheus \
      --restart unless-stopped \
      --network monitoring \
      -p 9090:9090 \
      -v /opt/monitoring/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro \
      prom/prometheus:latest \
      --config.file=/etc/prometheus/prometheus.yml

    GRAFANA_PASSWORD=$(openssl rand -base64 24 | tr -dc 'A-Za-z0-9' | head -c 20)

    echo "$GRAFANA_PASSWORD" > /opt/monitoring/grafana/admin-password
    chmod 600 /opt/monitoring/grafana/admin-password

    docker run -d \
      --name grafana \
      --restart unless-stopped \
      --network monitoring \
      -p 3000:3000 \
      -e GF_SECURITY_ADMIN_PASSWORD="$GRAFANA_PASSWORD" \
      grafana/grafana:latest
  USERDATA

  tags = {
    Name        = "${var.project_name}-${var.environment}-monitoring"
    Environment = var.environment
    Project     = var.project_name
    Role        = "Monitoring"
  }
}
