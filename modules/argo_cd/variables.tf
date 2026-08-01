variable "namespace" {
  description = "Namespace Argo CD is installed into."
  type        = string
  default     = "argocd"
}

variable "release_name" {
  description = "Name of the Argo CD Helm release."
  type        = string
  default     = "argocd"
}

variable "chart_version" {
  description = "Version of the argo/argo-cd Helm chart."
  type        = string
  default     = "10.2.1"
}

variable "server_service_type" {
  description = "Service type for argocd-server."
  type        = string
  default     = "LoadBalancer"
}

variable "application_name" {
  description = "Name of the Argo CD Application."
  type        = string
  default     = "django-app"
}

variable "git_repo_url" {
  description = "Git repository Argo CD treats as the source of truth."
  type        = string
}

variable "target_revision" {
  description = "Branch Argo CD tracks."
  type        = string
}

variable "chart_path" {
  description = "Path to the Helm chart inside the repository."
  type        = string
}

variable "destination_namespace" {
  description = "Namespace the Django application is deployed into."
  type        = string
  default     = "django"
}

variable "auto_sync" {
  description = "Enable automated sync with prune and selfHeal."
  type        = bool
  default     = true
}
