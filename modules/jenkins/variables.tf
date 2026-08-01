variable "namespace" {
  description = "Namespace Jenkins is installed into."
  type        = string
  default     = "jenkins"
}

variable "release_name" {
  description = "Name of the Helm release."
  type        = string
  default     = "jenkins"
}

variable "chart_version" {
  description = "Version of the jenkins/jenkins Helm chart."
  type        = string
  default     = "5.9.45"
}

variable "admin_user" {
  description = "Jenkins administrator username."
  type        = string
  default     = "admin"
}

variable "admin_password" {
  description = "Jenkins administrator password."
  type        = string
  sensitive   = true
}

variable "storage_class" {
  description = "StorageClass for the Jenkins home PVC. Created by the eks module."
  type        = string
  default     = "gp3"
}

variable "storage_size" {
  description = "Size of the Jenkins home volume."
  type        = string
  default     = "10Gi"
}

variable "controller_resources" {
  description = "CPU/memory requests and limits for the Jenkins controller."
  type = object({
    requests = object({ cpu = string, memory = string })
    limits   = object({ cpu = string, memory = string })
  })
  default = {
    requests = { cpu = "250m", memory = "512Mi" }
    limits   = { cpu = "500m", memory = "1Gi" }
  }
}

variable "oidc_provider_arn" {
  description = "ARN of the cluster IAM OIDC provider."
  type        = string
}

variable "oidc_provider_url" {
  description = "OIDC issuer URL of the cluster."
  type        = string
}

variable "ecr_repository_arn" {
  description = "ARN of the ECR repository the pipeline pushes to."
  type        = string
}

variable "agent_service_account" {
  description = "ServiceAccount used by Jenkins build agents."
  type        = string
  default     = "jenkins-agent"
}

variable "git_repo_url" {
  description = "HTTPS clone URL of the repository."
  type        = string
}

variable "git_branch" {
  description = "Branch the seed job builds and pushes back to."
  type        = string
}

variable "jenkinsfile" {
  description = "Path to the Jenkinsfile inside the repository."
  type        = string
  default     = "django/Jenkinsfile"
}

variable "github_owner" {
  description = "GitHub username stored in the credential."
  type        = string
}

variable "github_token" {
  description = "GitHub PAT with repo scope. Empty skips creating the credential."
  type        = string
  sensitive   = true
  default     = ""
}

variable "github_credentials_id" {
  description = "Jenkins credentials ID referenced by the Jenkinsfile."
  type        = string
  default     = "github-pat"
}
