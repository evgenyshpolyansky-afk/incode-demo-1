########################################### VPC and subnets ###########################################
module "vpc" {
  source   = "../../../modules/vpc"
  name     = "${var.project}-${var.environment}-${var.region}-vpc"
  vpc_cidr = var.vpc_cidr
  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

########################################### ECR for the sample app ####################################
module "ecr" {
  source = "../../../modules/ecr"
  name   = "${var.project}-app"
  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

########################################### Security Group for application ############################
module "app_sg" {
  source  = "terraform-aws-modules/security-group/aws"

  name        = "${var.project}-${var.environment}-${var.region}-app-sg"
  description = "Security group for application servers"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      description = "Allow HTTP (8080) from VPC"
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      cidr_blocks = var.vpc_cidr
    }
  ]

  egress_with_cidr_blocks = [
    {
      description = "Allow all outbound"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = {
    Environment = var.environment
    Project     = var.project
  }

  depends_on = [module.vpc]
}

########################################### Security Group for RDS ####################################
module "rds_sg" {
  source  = "terraform-aws-modules/security-group/aws"

  name        = "${var.project}-${var.environment}-${var.region}-rds-sg"
  description = "Security group for RDS allowing only MySQL (3306) within the VPC"
  vpc_id      = module.vpc.vpc_id

  # Allow MySQL only from the application security group
  ingress_with_source_security_group_id = [
    {
      description              = "Allow MySQL (3306) from app SG"
      from_port                = 3306
      to_port                  = 3306
      protocol                 = "tcp"
      source_security_group_id = module.app_sg.security_group_id
    }
  ]

  tags = {
    Environment = var.environment
    Project     = var.project
  }

  depends_on = [module.vpc, module.app_sg]
}

########################################### RDS instance ##############################################
module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "${var.project}-${var.environment}-${var.region}-rds"

  engine            = "mysql"
  engine_version    = "8.0.43"
  # Using Graviton t4g now that engine is 8.0.43 which supports ARM
  instance_class    = "db.t4g.micro"
  allocated_storage = 5

  db_name  = "demodb"
  username = "user"
  port     = "3306"

  iam_database_authentication_enabled = false

  vpc_security_group_ids = [module.rds_sg.security_group_id]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  # DB subnet group
  create_db_subnet_group = true
  subnet_ids             = [module.vpc.private_subnets[0], module.vpc.private_subnets[1]]

  # DB parameter group
  family = "mysql8.0"

  # DB option group
  major_engine_version = "8.0"

  # Database Deletion Protection
  deletion_protection = false
  skip_final_snapshot = false

  parameters = [
    {
      name  = "character_set_client"
      value = "utf8mb4"
    },
    {
      name  = "character_set_server"
      value = "utf8mb4"
    }
  ]

  options = [
    {
      option_name = "MARIADB_AUDIT_PLUGIN"

      option_settings = [
        {
          name  = "SERVER_AUDIT_EVENTS"
          value = "CONNECT"
        },
        {
          name  = "SERVER_AUDIT_FILE_ROTATIONS"
          value = "37"
        },
      ]
    },
  ]

  tags = {
    Environment = var.environment
    Project     = var.project
  }

  depends_on = [module.vpc, module.rds_sg]
}