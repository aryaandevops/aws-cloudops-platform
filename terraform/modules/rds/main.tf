resource "aws_security_group" "rds" {
  name        = "${var.project_name}-${var.environment}-rds-sg"
  description = "Security group for CloudOps RDS"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL from application EC2"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = ["sg-01c91aede89e7771b"]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-rds-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name        = "${var.project_name}-${var.environment}-db-subnet-group"
    Environment = var.environment
    Project     = var.project_name
  }
}
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-${var.environment}-db"

  engine         = "postgres"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp3"

  storage_encrypted = true

  db_name  = "cloudops"
  username = var.db_username
  password = var.db_password
  port     = 5432

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible = false

  backup_retention_period = 0

  deletion_protection = false
  skip_final_snapshot = true

  auto_minor_version_upgrade = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-db"
    Environment = var.environment
    Project     = var.project_name
    Role        = "Database"
  }
}
