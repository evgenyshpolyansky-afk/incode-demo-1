# Basic ASG configuration
variable "asg_name" {
  description = "Name prefix for ASG and related resources"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "ecr_repo" {
  description = "Full ECR image URI or repository (e.g. 123456789012.dkr.ecr.eu-central-1.amazonaws.com/my-repo)"
  type        = string
}

variable "app_version" {
  description = "Image tag/version to deploy from ECR"
  type        = string
  default     = "latest"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "instance_sg_id" {
  description = "Security group ID for EC2 instances"
  type        = string
}

variable "private_subnets" {
  description = "List of private subnet IDs for the ASG"
  type        = list(string)
}

variable "container_port" {
  description = "Port on which the container listens (inside EC2)"
  type        = number
  default     = 8080
}

variable "ssh_key_name" {
  description = "EC2 key pair name to attach to instances for SSH access"
  type        = string
  default     = null
}

variable "target_group_arn" {
  description = "ARN of the ALB target group to attach ASG instances to"
  type        = string
}

variable "db_endpoint" {
  description = "Optional DB endpoint to inject into the app instances as DB_ENDPOINT"
  type        = string
  default     = null
}


variable "db_secret_arn" {
  description = "Optional ARN of Secrets Manager secret that contains JSON with username and password"
  type        = string
  default     = null
}

# ASG scaling configuration
variable "max_size" {
  description = "Maximum number of instances in ASG"
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum number of instances in ASG"
  type        = number
  default     = 2
}

variable "desired_capacity" {
  description = "Desired number of instances in ASG"
  type        = number
  default     = 2
}
