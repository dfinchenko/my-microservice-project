# ---------------------------------------------------------------------------
# General
# ---------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region where all resources are created."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name prefix used for the VPC and in resource tags."
  type        = string
  default     = "final-project"
}

variable "environment" {
  description = "Environment tag applied to the database and other tagged resources."
  type        = string
  default     = "dev"
}

# ---------------------------------------------------------------------------
# State backend — must match backend.tf
# ---------------------------------------------------------------------------

variable "state_bucket_name" {
  description = "S3 bucket holding the Terraform state. Bucket names are globally unique — change the prefix if you fork this."
  type        = string
  default     = "denys-finchenko-tf-state-final-project"
}

variable "state_lock_table_name" {
  description = "DynamoDB table used for state locking."
  type        = string
  default     = "terraform-locks-final-project"
}

# ---------------------------------------------------------------------------
# Network
# ---------------------------------------------------------------------------

variable "vpc_cidr_block" {
  description = "CIDR block of the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "CIDR blocks of the public subnets, one per availability zone."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnets" {
  description = "CIDR blocks of the private subnets, one per availability zone."
  type        = list(string)
  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

# ---------------------------------------------------------------------------
# EKS
# ---------------------------------------------------------------------------

variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
  default     = "final-project-eks"
}

variable "kubernetes_version" {
  description = "Kubernetes control-plane version."
  type        = string
  default     = "1.34"
}

variable "node_instance_types" {
  description = "EC2 instance types for the managed node group."
  type        = list(string)
  default     = ["m7i-flex.large"]
}

variable "node_desired_size" {
  description = "Desired number of worker nodes at creation time."
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Lower bound cluster-autoscaler may scale the node group to."
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Upper bound cluster-autoscaler may scale the node group to."
  type        = number
  default     = 4
}

variable "enable_cluster_autoscaler" {
  description = "Install cluster-autoscaler so Pending pods trigger new nodes."
  type        = bool
  default     = true
}

variable "storage_class" {
  description = "Name of the gp3 StorageClass created by the eks module and used by Jenkins and Prometheus."
  type        = string
  default     = "gp3"
}

# ---------------------------------------------------------------------------
# ECR
# ---------------------------------------------------------------------------

variable "ecr_name" {
  description = "Name of the ECR repository that holds the Django image."
  type        = string
  default     = "final-project-ecr"
}

# ---------------------------------------------------------------------------
# Database
# ---------------------------------------------------------------------------

variable "use_aurora" {
  description = "false -> a single PostgreSQL RDS instance, true -> an Aurora PostgreSQL cluster with a writer and a reader. Aurora needs db.t4g.medium or larger in db_instance_class."
  type        = bool
  default     = false
}

variable "db_identifier" {
  description = "Base name of the database: RDS instance identifier, or Aurora cluster identifier plus the -cluster suffix."
  type        = string
  default     = "final-project-db"
}

variable "db_instance_class" {
  description = "Instance class of the database. db.t3.micro is free-tier eligible for RDS; Aurora needs db.t4g.medium or larger."
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Name of the database created inside the instance/cluster."
  type        = string
  default     = "djangodb"
}

variable "db_username" {
  description = "Master username of the database."
  type        = string
  default     = "djangouser"
}

variable "db_password" {
  description = "Master password. Leave null and Terraform generates one; read it back with: terraform output -raw db_password. Pass via TF_VAR_db_password."
  type        = string
  sensitive   = true
  default     = null
}

variable "db_backup_retention_period" {
  description = "Days automated backups are kept. Free-tier accounts are capped at 1 — anything higher fails with FreeTierRestrictionError."
  type        = number
  default     = 1
}

variable "db_allowed_cidr_blocks" {
  description = "Extra CIDR blocks allowed to reach the database on top of the EKS node security group. Normally empty."
  type        = list(string)
  default     = []
}

# ---------------------------------------------------------------------------
# Application
# ---------------------------------------------------------------------------

variable "app_namespace" {
  description = "Namespace the Django application is deployed into by Argo CD."
  type        = string
  default     = "django"
}

variable "app_db_secret_name" {
  description = "Secret Terraform writes the RDS endpoint and credentials into. Referenced from charts/django-app/values.yaml as database.existingSecret."
  type        = string
  default     = "django-db"
}

# ---------------------------------------------------------------------------
# Git — the source of truth for both Jenkins and Argo CD
# ---------------------------------------------------------------------------

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
  default     = "final-project"
}

variable "chart_path" {
  description = "Path to the Django Helm chart inside the repository."
  type        = string
  default     = "charts/django-app"
}

variable "jenkinsfile_path" {
  description = "Path to the Jenkinsfile inside the repository."
  type        = string
  default     = "django/Jenkinsfile"
}

variable "github_token" {
  description = "GitHub PAT (scope: repo) used by Jenkins to push the updated image.tag. Pass via TF_VAR_github_token."
  type        = string
  sensitive   = true
  default     = ""
}

# ---------------------------------------------------------------------------
# Jenkins
# ---------------------------------------------------------------------------

variable "jenkins_admin_user" {
  description = "Jenkins administrator username."
  type        = string
  default     = "admin"
}

variable "jenkins_admin_password" {
  description = "Jenkins administrator password. Pass via TF_VAR_jenkins_admin_password."
  type        = string
  sensitive   = true
  default     = "admin123"
}

# ---------------------------------------------------------------------------
# Monitoring
# ---------------------------------------------------------------------------

variable "monitoring_namespace" {
  description = "Namespace the monitoring stack is installed into."
  type        = string
  default     = "monitoring"
}

variable "grafana_admin_user" {
  description = "Grafana administrator username."
  type        = string
  default     = "admin"
}

variable "grafana_admin_password" {
  description = "Grafana administrator password. Pass via TF_VAR_grafana_admin_password."
  type        = string
  sensitive   = true
  default     = "admin123"
}

variable "grafana_service_type" {
  description = "Service type for Grafana. ClusterIP keeps it behind port-forward; LoadBalancer publishes it and adds an ELB to the bill."
  type        = string
  default     = "ClusterIP"
}

variable "prometheus_retention" {
  description = "How long Prometheus keeps samples."
  type        = string
  default     = "3d"
}
