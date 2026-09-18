terraform {
  backend "s3" {
    bucket       = "aws-cloudops-platform-tfstate-012646746635"
    key          = "terraform/dev/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}

