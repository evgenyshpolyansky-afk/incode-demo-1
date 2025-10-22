variable "alb_name" {
	description = "Load balancer name"
	type        = string
}

variable "alb_sg_id" {
	description = "Security group id to attach to the ALB"
	type        = string
}

variable "public_subnets" {
	description = "List of public subnet ids for the ALB"
	type        = list(string)
}

variable "vpc_id" {
	description = "VPC id where the ALB will be created"
	type        = string
}

variable "target_port" {
	description = "Port where target instances listen"
	type        = number
	default     = 8080
}

variable "health_check_path" {
	description = "HTTP path used by ALB health checks"
	type        = string
	default     = "/liveness"
}

variable "tags" {
	description = "Additional tags to apply to ALB resources"
	type        = map(string)
	default     = {}
}
