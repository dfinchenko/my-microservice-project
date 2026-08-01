variable "namespace" {
  description = "Namespace the monitoring stack is installed into."
  type        = string
  default     = "monitoring"
}

variable "release_name" {
  description = "Name of the kube-prometheus-stack Helm release."
  type        = string
  default     = "kube-prometheus-stack"
}

variable "chart_version" {
  description = "Version of the prometheus-community/kube-prometheus-stack chart."
  type        = string
  default     = "88.0.1"
}

variable "grafana_service_name" {
  description = "Name of the Grafana Service. The default keeps `kubectl port-forward svc/grafana 3000:80 -n monitoring` working."
  type        = string
  default     = "grafana"
}

variable "grafana_service_type" {
  description = "Service type for Grafana. ClusterIP keeps it reachable through port-forward only; LoadBalancer publishes it (and adds an ELB to the bill)."
  type        = string
  default     = "ClusterIP"

  validation {
    condition     = contains(["ClusterIP", "NodePort", "LoadBalancer"], var.grafana_service_type)
    error_message = "grafana_service_type must be ClusterIP, NodePort or LoadBalancer."
  }
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
}

variable "storage_class" {
  description = "StorageClass for the Prometheus PVC. Created by the eks module."
  type        = string
  default     = "gp3"
}

variable "prometheus_storage_size" {
  description = "Size of the Prometheus data volume."
  type        = string
  default     = "10Gi"
}

variable "prometheus_retention" {
  description = "How long Prometheus keeps samples. Short by design — this is a demo cluster, not a long-term store."
  type        = string
  default     = "3d"
}

variable "app_namespace" {
  description = "Namespace the Django application runs in. Used by the application alert rules."
  type        = string
  default     = "django"
}
