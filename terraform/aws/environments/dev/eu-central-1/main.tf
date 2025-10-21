# VPC and subnets
module "vpc" {
  source   = "../../../modules/vpc"
  name     = "${var.environment}-${var.region}-vpc"
  vpc_cidr = var.vpc_cidr
  tags = {
    Environment = var.environment
    Project     = "incode-demo-1"
  }
}

# ECR for the sample app
module "ecr" {
  source = "../../../modules/ecr"
  name   = "incode-demo-1-app"
  tags = {
    Environment = var.environment
    Project     = "incode-demo-1"
  }
}
