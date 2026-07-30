# ---- eks module ----
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

# ---- ecr module ----
output "ecr_repository_url" {
  description = "URL of the ECR repository. Goes into charts/django-app/values.yaml as image.repository."
  value       = module.ecr.repository_url
}

# ---- vpc module ----
output "vpc_id" {
  description = "ID of the VPC."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = module.vpc.private_subnet_ids
}

# ---- jenkins module ----
output "jenkins_release" {
  description = "Name of the Jenkins Helm release."
  value       = module.jenkins.jenkins_release_name
}

output "jenkins_namespace" {
  description = "Namespace Jenkins is installed into."
  value       = module.jenkins.jenkins_namespace
}

output "jenkins_url" {
  description = "External URL of the Jenkins UI."
  value       = module.jenkins.jenkins_url
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

# ---- argo_cd module ----
output "argocd_release" {
  description = "Name of the Argo CD Helm release."
  value       = module.argo_cd.argocd_release_name
}

output "argocd_namespace" {
  description = "Namespace Argo CD is installed into."
  value       = module.argo_cd.argocd_namespace
}

output "argocd_hostname" {
  description = "External hostname of argocd-server."
  value       = module.argo_cd.argocd_hostname
}

output "argocd_url" {
  description = "External URL of the Argo CD UI."
  value       = module.argo_cd.argocd_url
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
