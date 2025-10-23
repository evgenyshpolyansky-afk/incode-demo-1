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

########################################### Security Group for application load balancer ##############
module "alb_sg" {
  source  = "terraform-aws-modules/security-group/aws"

  name        = "${var.project}-${var.environment}-${var.region}-alb-sg"
  description = "Security group for application load balancer"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      description = "Allow HTTP (8080) from VPC"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = var.my_external_ip_address
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

########################################### Security Group for Bastion ############################
module "bastion_sg" {
  source  = "terraform-aws-modules/security-group/aws"

  name        = "${var.project}-${var.environment}-${var.region}-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      description = "Allow SSH (22) from My IP"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.my_external_ip_address
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
    },
    {
      description = "Allow SSH (22) from VPC"
      from_port   = 22
      to_port     = 22
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


########################################### ALB #######################################################
module "alb" {
  source = "../../../modules/alb"

  alb_name        = "${var.project}-${var.environment}-alb"
  alb_sg_id       = module.alb_sg.security_group_id
  public_subnets  = module.vpc.public_subnets
  vpc_id          = module.vpc.vpc_id
  target_port     = 8080
  health_check_path = "/liveness"

  tags = {
    Environment = var.environment
    Project     = var.project
  }

}

########################################### Bastion Host ##############################################
module "bastion" {
  source = "../../../modules/ec2"

  region               = var.region
  vpc_id               = module.vpc.vpc_id
  instance_name        = "${var.project}-${var.environment}-bastion"
  instance_type        = "t3.micro"
  subnet_id            = module.vpc.public_subnets[0]
  security_group_ids   = [module.bastion_sg.security_group_id]
  key_name             = var.ssh_key_name
  associate_public_ip  = true

  tags = {
    Environment = var.environment
    Project     = var.project
  }

  depends_on = [module.vpc, module.bastion_sg]
}

########################################### Auto Scaling Group ########################################
module "asg" {
  source = "../../../modules/asg"

  asg_name          = "${var.project}-${var.environment}-asg"
  instance_type     = "t3.micro"
  instance_sg_id    = module.app_sg.security_group_id
  ecr_repo          = module.ecr.repository_url
  container_port    = 8080
  region            = var.region
  app_version       = "0.1.2"

  min_size         = 2
  max_size         = 2
  desired_capacity = 2

  db_endpoint      = module.db.db_instance_endpoint
  db_secret_arn    = module.db.db_instance_master_user_secret_arn

  ssh_key_name     = var.ssh_key_name

  private_subnets   = module.vpc.nat_subnets
  target_group_arn  = module.alb.target_group_arn

  depends_on = [module.vpc, module.app_sg, module.alb]
}