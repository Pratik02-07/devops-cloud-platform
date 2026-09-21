provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "devops-cloud-platform"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}