output "argocd_release_name" {
  description = "Name of the Argo CD Helm release."
  value       = helm_release.argocd.name
}

output "argocd_namespace" {
  description = "Namespace Argo CD is installed into."
  value       = helm_release.argocd.namespace
}

output "argocd_hostname" {
  description = "External hostname of argocd-server."
  value = try(
    data.kubernetes_service.argocd_server.status[0].load_balancer[0].ingress[0].hostname,
    ""
  )
}

output "argocd_url" {
  description = "External URL of the Argo CD UI."
  value = try(
    "http://${data.kubernetes_service.argocd_server.status[0].load_balancer[0].ingress[0].hostname}",
    ""
  )
}

output "argocd_admin_user" {
  description = "Argo CD administrator username."
  value       = "admin"
}

output "argocd_initial_admin_password" {
  description = "Initial admin password. Empty once the password has been changed."
  value = try(
    base64decode(data.kubernetes_resources.argocd_admin.objects[0].data.password),
    ""
  )
  sensitive = true
}

output "application_name" {
  description = "Name of the Argo CD Application."
  value       = var.application_name
}

output "application_source" {
  description = "Git source the Application watches."
  value       = "${var.git_repo_url} @ ${var.target_revision} : ${var.chart_path}"
}
