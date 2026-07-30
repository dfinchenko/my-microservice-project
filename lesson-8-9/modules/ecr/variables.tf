variable "ecr_name" {
  description = "Name of the ECR repository."
  type        = string
}

variable "scan_on_push" {
  description = "Whether to scan images for vulnerabilities automatically on push."
  type        = bool
  default     = true
}

variable "image_tag_mutability" {
  description = "Tag mutability setting for the repository (MUTABLE or IMMUTABLE)."
  type        = string
  default     = "MUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be either MUTABLE or IMMUTABLE."
  }
}

variable "force_delete" {
  description = "If true, the repository can be deleted even if it still contains images."
  type        = bool
  default     = true
}

variable "max_image_count" {
  description = "Maximum number of tagged images to retain in the repository."
  type        = number
  default     = 10
}

variable "repository_principals" {
  description = "Optional map of principals granted pull/push access. Defaults to the current account root when null."
  type        = any
  default     = null
}
