variable "name" {
  description = "Repository name"
  type        = string
}

variable "image_tag_mutability" {
  description = "Image tag mutability: MUTABLE or IMMUTABLE"
  type        = string
  default     = "MUTABLE"
}

variable "scan_on_push" {
  description = "Enable image scanning on push"
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "Encryption type for images (AES256 or KMS)"
  type        = string
  default     = "AES256"
}

variable "kms_key" {
  description = "KMS key ARN to use if encryption_type == 'KMS'"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
