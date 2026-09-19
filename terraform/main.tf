module "vpc" {
  source = "./modules/vpc"

  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  environment        = var.environment
  project_name       = var.project_name
}

module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
  environment  = var.environment
}

module "ec2" {
  source = "./modules/ec2"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  subnet_id             = module.vpc.public_subnet_ids[0]
  instance_profile_name = module.iam.ec2_instance_profile_name
  alb_security_group_id = module.alb.alb_security_group_id
  instance_type         = "t3.micro"
}

module "rds" {
  source = "./modules/rds"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  db_username = var.db_username
  db_password = var.db_password
}

module "alb" {
  source = "./modules/alb"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  ec2_security_group_id = module.ec2.security_group_id
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = module.alb.alb_dns_name
}

module "asg" {
  source = "./modules/asg"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  subnet_ids            = module.vpc.public_subnet_ids
  ec2_security_group_id = module.ec2.security_group_id
  instance_profile_name = module.iam.ec2_instance_profile_name
  target_group_arn      = module.alb.target_group_arn

  instance_type = "t3.micro"
  ami_id        = "ami-025d99823a4caad37"
  app_image_tag = var.app_image_tag
}

module "monitoring" {
  source = "./modules/monitoring"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  vpc_cidr              = var.vpc_cidr
  subnet_id             = module.vpc.public_subnet_ids[1]
  app_security_group_id = module.ec2.security_group_id
  instance_type         = "t3.micro"
}

resource "aws_security_group_rule" "node_exporter_from_monitoring" {
  type                     = "ingress"
  from_port                = 9100
  to_port                  = 9100
  protocol                 = "tcp"
  security_group_id        = module.ec2.security_group_id
  source_security_group_id = module.monitoring.monitoring_security_group_id
  description              = "Node Exporter from monitoring"
}
