# ---------------------------------------------------------------------------
# Network
# ---------------------------------------------------------------------------

output "vpc_id" {
  description = "ID of the VPC."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets (load balancers, NAT)."
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets (worker nodes, database)."
  value       = module.vpc.private_subnet_ids
}

# ---------------------------------------------------------------------------
# EKS
# ---------------------------------------------------------------------------

output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "API server endpoint of the EKS cluster."
  value       = module.eks.cluster_endpoint
}

output "oidc_provider_arn" {
  description = "ARN of the cluster IAM OIDC provider (basis for IRSA)."
  value       = module.eks.oidc_provider_arn
}

output "node_security_group_id" {
  description = "Security group of the worker nodes — the only source allowed into the database."
  value       = module.eks.node_security_group_id
}

output "node_group_asg_name" {
  description = "Auto Scaling group cluster-autoscaler resizes."
  value       = module.eks.node_group_asg_name
}

output "cluster_autoscaler_role_arn" {
  description = "IRSA role assumed by cluster-autoscaler."
  value       = module.eks.cluster_autoscaler_role_arn
}

output "kubeconfig_command" {
  description = "Command that points kubectl at this cluster."
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

# ---------------------------------------------------------------------------
# ECR
# ---------------------------------------------------------------------------

output "ecr_repository_url" {
  description = "URL of the ECR repository. Goes into charts/django-app/values.yaml as image.repository."
  value       = module.ecr.repository_url
}

# ---------------------------------------------------------------------------
# Database
# ---------------------------------------------------------------------------

output "db_is_aurora" {
  description = "True when the RDS module created an Aurora cluster instead of a standard instance."
  value       = module.rds.is_aurora
}

output "db_identifier" {
  description = "Identifier of the Aurora cluster or of the RDS instance."
  value       = module.rds.identifier
}

output "db_endpoint" {
  description = "Writer hostname of the database."
  value       = module.rds.endpoint
}

output "db_reader_endpoint" {
  description = "Read-only hostname: the Aurora reader endpoint, or null for a single RDS instance."
  value       = module.rds.reader_endpoint
}

output "db_port" {
  description = "Port the database listens on."
  value       = module.rds.port
}

output "db_name" {
  description = "Name of the initial database."
  value       = module.rds.db_name
}

output "db_username" {
  description = "Master username of the database."
  value       = module.rds.username
}

output "db_password" {
  description = "Master password. Read with: terraform output -raw db_password"
  value       = module.rds.password
  sensitive   = true
}

output "db_engine" {
  description = "Engine and version actually deployed."
  value       = "${module.rds.engine} ${module.rds.engine_version}"
}

output "db_security_group_id" {
  description = "Security group guarding the database."
  value       = module.rds.security_group_id
}

output "app_db_secret" {
  description = "Kubernetes Secret the Django chart reads the database connection from."
  value       = "${kubernetes_secret.app_database.metadata[0].namespace}/${kubernetes_secret.app_database.metadata[0].name}"
}

# ---------------------------------------------------------------------------
# Jenkins
# ---------------------------------------------------------------------------

output "jenkins_namespace" {
  description = "Namespace Jenkins is installed into."
  value       = module.jenkins.jenkins_namespace
}

output "jenkins_url" {
  description = "External URL of the Jenkins UI."
  value       = module.jenkins.jenkins_url
}

output "jenkins_port_forward_command" {
  description = "Command that opens Jenkins on http://localhost:8080."
  value       = "kubectl port-forward svc/${module.jenkins.jenkins_release_name} 8080:8080 -n ${module.jenkins.jenkins_namespace}"
}

output "jenkins_admin_user" {
  description = "Jenkins administrator username."
  value       = module.jenkins.jenkins_admin_user
}

output "jenkins_admin_password" {
  description = "Jenkins administrator password. Read with: terraform output -raw jenkins_admin_password"
  value       = module.jenkins.jenkins_admin_password
  sensitive   = true
}

output "jenkins_agent_role_arn" {
  description = "IRSA role the Kaniko agent assumes to push to ECR."
  value       = module.jenkins.jenkins_agent_role_arn
}

output "jenkins_github_credentials_configured" {
  description = "True when Terraform created the github-pat credential from TF_VAR_github_token."
  value       = module.jenkins.github_credentials_configured
}

# ---------------------------------------------------------------------------
# Argo CD
# ---------------------------------------------------------------------------

output "argocd_namespace" {
  description = "Namespace Argo CD is installed into."
  value       = module.argo_cd.argocd_namespace
}

output "argocd_url" {
  description = "External URL of the Argo CD UI."
  value       = module.argo_cd.argocd_url
}

output "argocd_port_forward_command" {
  description = "Command that opens Argo CD on https://localhost:8081."
  value       = "kubectl port-forward svc/${module.argo_cd.argocd_release_name}-server 8081:443 -n ${module.argo_cd.argocd_namespace}"
}

output "argocd_admin_user" {
  description = "Argo CD administrator username."
  value       = module.argo_cd.argocd_admin_user
}

output "argocd_initial_admin_password" {
  description = "Argo CD admin password. Read with: terraform output -raw argocd_initial_admin_password"
  value       = module.argo_cd.argocd_initial_admin_password
  sensitive   = true
}

output "argocd_application" {
  description = "Name of the Argo CD Application tracking the Django chart."
  value       = module.argo_cd.application_name
}

output "argocd_application_source" {
  description = "Git repo, branch and chart path the Application watches."
  value       = module.argo_cd.application_source
}

# ---------------------------------------------------------------------------
# Monitoring
# ---------------------------------------------------------------------------

output "monitoring_namespace" {
  description = "Namespace the monitoring stack is installed into."
  value       = module.monitoring.monitoring_namespace
}

output "grafana_port_forward_command" {
  description = "Command that opens Grafana on http://localhost:3000."
  value       = module.monitoring.grafana_port_forward_command
}

output "grafana_url" {
  description = "External URL of Grafana. Empty unless grafana_service_type is LoadBalancer."
  value       = module.monitoring.grafana_url
}

output "grafana_admin_user" {
  description = "Grafana administrator username."
  value       = module.monitoring.grafana_admin_user
}

output "grafana_admin_password" {
  description = "Grafana administrator password. Read with: terraform output -raw grafana_admin_password"
  value       = module.monitoring.grafana_admin_password
  sensitive   = true
}

output "prometheus_port_forward_command" {
  description = "Command that opens the Prometheus UI on http://localhost:9090."
  value       = module.monitoring.prometheus_port_forward_command
}
