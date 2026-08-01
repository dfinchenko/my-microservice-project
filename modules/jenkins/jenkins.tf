resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = var.namespace

    labels = {
      name      = var.namespace
      ManagedBy = "Terraform"
    }
  }
}

# Picked up by the kubernetes-credentials-provider plugin as credential "github-pat".
resource "kubernetes_secret" "github" {
  count = var.github_token != "" ? 1 : 0

  metadata {
    name      = var.github_credentials_id
    namespace = kubernetes_namespace.jenkins.metadata[0].name

    labels = {
      "jenkins.io/credentials-type" = "usernamePassword"
    }

    annotations = {
      "jenkins.io/credentials-description" = "GitHub PAT used by the pipeline to push the updated image tag"
    }
  }

  type = "Opaque"

  data = {
    username = var.github_owner
    password = var.github_token
  }
}

resource "helm_release" "jenkins" {
  name       = var.release_name
  namespace  = kubernetes_namespace.jenkins.metadata[0].name
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"
  version    = var.chart_version

  create_namespace = false

  # Plugins are downloaded on first start.
  timeout = 900
  wait    = true

  values = [
    templatefile("${path.module}/values.yaml", {
      admin_user            = var.admin_user
      admin_password        = var.admin_password
      cpu_request           = var.controller_resources.requests.cpu
      memory_request        = var.controller_resources.requests.memory
      cpu_limit             = var.controller_resources.limits.cpu
      memory_limit          = var.controller_resources.limits.memory
      storage_class         = var.storage_class
      storage_size          = var.storage_size
      agent_service_account = var.agent_service_account
      agent_role_arn        = aws_iam_role.agent.arn
      git_repo_url          = var.git_repo_url
      git_branch            = var.git_branch
      jenkinsfile           = var.jenkinsfile
      # Empty when no token is supplied, so the seed job clones the public repo
      # anonymously instead of referencing a credential that does not exist.
      github_credentials_id = var.github_token != "" ? var.github_credentials_id : ""
    })
  ]

  depends_on = [
    kubernetes_secret.github,
    aws_iam_role_policy_attachment.agent_ecr,
  ]
}

data "kubernetes_service" "jenkins" {
  metadata {
    name      = var.release_name
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }

  depends_on = [helm_release.jenkins]
}
