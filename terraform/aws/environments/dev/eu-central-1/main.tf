module "vpc" {
  source   = "../../../modules/vpc"
  name     = "${var.environment}-${var.region}-vpc"
  vpc_cidr = var.vpc_cidr
}

output "vpc_id" {
  value = module.vpc.vpc_id
}
