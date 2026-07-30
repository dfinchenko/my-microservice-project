variable "aws_region" {
  description = "AWS region where all resources are created."
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
  default     = "lesson-8-9-eks"
}

variable "ecr_name" {
  description = "Name of the ECR repository that holds the Django image."
  type        = string
  default     = "lesson-8-9-ecr"
}

variable "github_owner" {
  description = "GitHub user or organisation that owns the repository."
  type        = string
  default     = "dfinchenko"
}

variable "github_repo" {
  description = "Repository holding the Helm chart, the Dockerfile and the Jenkinsfile."
  type        = string
  default     = "my-microservice-project"
}

variable "github_branch" {
  description = "Branch Jenkins pushes the new image.tag to and Argo CD tracks."
  type        = string
  default     = "lesson-8-9"
}

variable "chart_path" {
  description = "Path to the Django Helm chart inside the repository."
  type        = string
  default     = "lesson-8-9/charts/django-app"
}

variable "jenkinsfile_path" {
  description = "Path to the Jenkinsfile inside the repository."
  type        = string
  default     = "lesson-8-9/Jenkinsfile"
}

variable "github_token" {
  description = "GitHub PAT (scope: repo) used by Jenkins to push the updated image.tag. Pass via TF_VAR_github_token."
  type        = string
  sensitive   = true
  default     = ""
}

variable "jenkins_admin_user" {
  description = "Jenkins administrator username."
  type        = string
  default     = "admin"
}

variable "jenkins_admin_password" {
  description = "Jenkins administrator password."
  type        = string
  sensitive   = true
  default     = "admin123"
}

variable "jenkins_storage_class" {
  description = "StorageClass for the Jenkins home PVC."
  type        = string
  default     = "gp3"
}
