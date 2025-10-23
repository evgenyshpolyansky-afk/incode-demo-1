variable "environment" {
  description = "Environment name (dev/stage/prod)"
  type        = string
  default     = "dev"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "incode-demo-1"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "vpc_cidr" {
  description = "CIDR for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "ssh_key_name" {
  description = "EC2 key pair name to attach to instances for SSH access"
  type        = string
  default     = "incode-demo-1-eu-central-1-key"
}

variable "my_external_ip_address" {
  description = "My external IP address"
  type        = string
  default     = "87.116.165.146/32"
}