resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace

    labels = {
      name      = var.namespace
      ManagedBy = "Terraform"
    }
  }
}

resource "helm_release" "argocd" {
  name       = var.release_name
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.chart_version

  create_namespace = false

  timeout = 900
  wait    = true

  values = [
    templatefile("${path.module}/values.yaml", {
      server_service_type = var.server_service_type
    })
  ]
}

# App-of-apps: registers the Application and the Git repository.
resource "helm_release" "argocd_apps" {
  name      = "${var.release_name}-apps"
  namespace = kubernetes_namespace.argocd.metadata[0].name
  chart     = "${path.module}/charts"

  values = [
    yamlencode({
      argocdNamespace = var.namespace

      repositories = [
        {
          name = var.application_name
          url  = var.git_repo_url
          type = "git"
        }
      ]

      applications = [
        {
          name                 = var.application_name
          project              = "default"
          repoURL              = var.git_repo_url
          targetRevision       = var.target_revision
          path                 = var.chart_path
          destinationServer    = "https://kubernetes.default.svc"
          destinationNamespace = var.destination_namespace
          autoSync             = var.auto_sync
        }
      ]
    })
  ]

  # The Application CRD comes with the Argo CD chart.
  depends_on = [helm_release.argocd]
}

data "kubernetes_service" "argocd_server" {
  metadata {
    name      = "${var.release_name}-server"
    namespace = kubernetes_namespace.argocd.metadata[0].name
  }

  depends_on = [helm_release.argocd]
}

# Plural data source: returns an empty list instead of failing once the initial
# admin secret is removed.
data "kubernetes_resources" "argocd_admin" {
  api_version    = "v1"
  kind           = "Secret"
  namespace      = kubernetes_namespace.argocd.metadata[0].name
  field_selector = "metadata.name=argocd-initial-admin-secret"

  depends_on = [helm_release.argocd]
}
