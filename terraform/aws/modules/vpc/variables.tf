variable "name" {
  description = "Name tag for resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_count" {
  description = "Number of public subnets to create"
  type        = number
  default     = 2
  validation {
    condition     = var.public_subnet_count > 0
    error_message = "public_subnet_count must be > 0"
  }
}

variable "nat_subnet_count" {
  description = "Number of NAT subnets (and NAT gateways) to create. Should be <= public_subnet_count"
  type        = number
  default     = 2
  validation {
    condition     = var.nat_subnet_count >= 0 && var.nat_subnet_count <= var.public_subnet_count
    error_message = "nat_subnet_count must be >= 0 and <= public_subnet_count"
  }
}

variable "private_subnet_count" {
  description = "Number of private subnets to create"
  type        = number
  default     = 2
  validation {
    condition     = var.private_subnet_count >= 0
    error_message = "private_subnet_count must be >= 0"
  }
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
