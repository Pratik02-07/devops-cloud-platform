locals {
  project_name = var.project_name
  environment  = var.environment

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}