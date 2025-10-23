
variable "vpc_id" {
  description = "VPC id where the instance will be launched"
  type        = string
}

variable "subnet_id" {
  description = "Subnet id where the instance will be launched"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "SSH key name to attach to instance"
  type        = string
  default     = null
}

variable "associate_public_ip" {
  description = "Whether to associate a public IP to the instance"
  type        = bool
  default     = false
}

variable "user_data" {
  description = "Optional user data script"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to assign to resources"
  type        = map(string)
  default     = {}
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to the instance"
  type        = list(string)
  default     = []
}

variable "instance_name" {
  description = "Name tag value for the instance"
  type        = string
  default     = "ec2-instance"
}

variable "region" {
  description = "AWS region for resource ARN construction"
  type        = string
}

variable "db_secret_arn" {
  description = "Optional ARN of Secrets Manager secret that contains JSON with username and password"
  type        = string
  default     = ""
}
