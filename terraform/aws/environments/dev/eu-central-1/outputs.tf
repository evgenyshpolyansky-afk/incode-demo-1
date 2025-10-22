output "environment" {
  value = var.environment
}

output "region" {
  value = var.region
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "private_subnets" {
  value = module.vpc.private_subnets
}
output "nat_subnets" {
  value = module.vpc.nat_subnets
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "app_sg_id" {
  value = module.app_sg.security_group_id
}

output "rds_sg_id" {
  value = module.rds_sg.security_group_id
}

output "db_instance_endpoint" {
  value = module.db.db_instance_endpoint
}

output "db_instance_master_user_secret_arn" {
  value = module.db.db_instance_master_user_secret_arn
}