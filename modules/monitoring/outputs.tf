output "monitoring_release_name" {
  description = "Name of the kube-prometheus-stack Helm release."
  value       = helm_release.kube_prometheus_stack.name
}

output "monitoring_namespace" {
  description = "Namespace the monitoring stack is installed into."
  value       = helm_release.kube_prometheus_stack.namespace
}

output "grafana_service_name" {
  description = "Name of the Grafana Service."
  value       = var.grafana_service_name
}

output "grafana_port_forward_command" {
  description = "Command that opens Grafana on http://localhost:3000."
  value       = "kubectl port-forward svc/${var.grafana_service_name} 3000:80 -n ${var.namespace}"
}

output "grafana_url" {
  description = "External URL of Grafana. Empty unless grafana_service_type is LoadBalancer."
  value = try(
    "http://${data.kubernetes_service.grafana.status[0].load_balancer[0].ingress[0].hostname}",
    ""
  )
}

output "grafana_admin_user" {
  description = "Grafana administrator username."
  value       = var.grafana_admin_user
}

output "grafana_admin_password" {
  description = "Grafana administrator password. Read with: terraform output -raw grafana_admin_password"
  value       = var.grafana_admin_password
  sensitive   = true
}

output "prometheus_service_name" {
  description = "Service that fronts Prometheus inside the cluster."
  value       = "${var.release_name}-prometheus"
}

output "prometheus_port_forward_command" {
  description = "Command that opens the Prometheus UI on http://localhost:9090."
  value       = "kubectl port-forward svc/${var.release_name}-prometheus 9090:9090 -n ${var.namespace}"
}

output "dashboard_config_map" {
  description = "ConfigMap holding the Django dashboard the Grafana sidecar loads."
  value       = kubernetes_config_map.django_dashboard.metadata[0].name
}
