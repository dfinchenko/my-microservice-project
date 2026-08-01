resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.namespace

    labels = {
      name      = var.namespace
      ManagedBy = "Terraform"
    }
  }
}

resource "helm_release" "kube_prometheus_stack" {
  name       = var.release_name
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.chart_version

  create_namespace = false

  timeout = 1200
  wait    = true

  values = [
    templatefile("${path.module}/values.yaml", {
      grafana_admin_user     = var.grafana_admin_user
      grafana_admin_password = var.grafana_admin_password
      grafana_service_type   = var.grafana_service_type
      grafana_service_name   = var.grafana_service_name
      storage_class          = var.storage_class
      prometheus_storage     = var.prometheus_storage_size
      prometheus_retention   = var.prometheus_retention
      app_namespace          = var.app_namespace
    })
  ]
}

# Picked up by the Grafana sidecar, so dashboards live in Git rather than in
# Grafana's database.
resource "kubernetes_config_map" "django_dashboard" {
  metadata {
    name      = "grafana-dashboard-django-app"
    namespace = kubernetes_namespace.monitoring.metadata[0].name

    labels = {
      grafana_dashboard = "1"
      ManagedBy         = "Terraform"
    }
  }

  data = {
    "django-app.json" = file("${path.module}/dashboards/django-app.json")
  }

  depends_on = [helm_release.kube_prometheus_stack]
}

data "kubernetes_service" "grafana" {
  metadata {
    name      = var.grafana_service_name
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  depends_on = [helm_release.kube_prometheus_stack]
}
