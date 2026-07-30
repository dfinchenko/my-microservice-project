output "jenkins_release_name" {
  description = "Name of the Jenkins Helm release."
  value       = helm_release.jenkins.name
}

output "jenkins_namespace" {
  description = "Namespace Jenkins is installed into."
  value       = helm_release.jenkins.namespace
}

output "jenkins_url" {
  description = "External URL of the Jenkins UI."
  value = try(
    "http://${data.kubernetes_service.jenkins.status[0].load_balancer[0].ingress[0].hostname}",
    ""
  )
}

output "jenkins_admin_user" {
  description = "Jenkins administrator username."
  value       = var.admin_user
}

output "jenkins_admin_password" {
  description = "Jenkins administrator password."
  value       = var.admin_password
  sensitive   = true
}

output "jenkins_agent_service_account" {
  description = "ServiceAccount the build agents run as."
  value       = var.agent_service_account
}

output "jenkins_agent_role_arn" {
  description = "IRSA role assumed by build agents to push to ECR."
  value       = aws_iam_role.agent.arn
}

output "github_credentials_configured" {
  description = "Whether Terraform created the GitHub credential."
  value       = nonsensitive(var.github_token != "")
}
