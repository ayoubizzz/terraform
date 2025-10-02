module "vpc" {
  source = "./modules/vpc"

  name            = "ec2-lambda-s3-rds-vpc"
  vpc_cidr        = "10.0.0.0/16"
  region          = var.aws_region
  public_subnets  = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnets = ["10.0.10.0/24", "10.0.11.0/24"]
  db_subnets      = ["10.0.20.0/24", "10.0.21.0/24"]
  nat_gateway_count = 1
  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# Expose module outputs as top-level outputs
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "db_subnet_ids" {
  value = module.vpc.db_subnet_ids
}