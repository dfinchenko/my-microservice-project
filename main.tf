locals {
  project      = var.project_name
  git_repo_url = "https://github.com/${var.github_owner}/${var.github_repo}.git"
}

# Bootstrapped with -target before the rest exists; see backend.tf.
module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = var.state_bucket_name
  table_name  = var.state_lock_table_name
}

module "vpc" {
  source = "./modules/vpc"

  vpc_name           = "${local.project}-vpc"
  vpc_cidr_block     = var.vpc_cidr_block
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  availability_zones = [for z in ["a", "b", "c"] : "${var.aws_region}${z}"]
  cluster_name       = var.cluster_name
}

module "ecr" {
  source       = "./modules/ecr"
  ecr_name     = var.ecr_name
  scan_on_push = true
}

module "eks" {
  source = "./modules/eks"

  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version
  node_ami_type      = "AL2023_x86_64_STANDARD"

  # The control plane places ENIs in both tiers; the nodes only run in private.
  subnet_ids         = concat(module.vpc.public_subnet_ids, module.vpc.private_subnet_ids)
  private_subnet_ids = module.vpc.private_subnet_ids

  node_instance_types = var.node_instance_types
  node_desired_size   = var.node_desired_size
  node_min_size       = var.node_min_size
  node_max_size       = var.node_max_size

  enable_metrics_server     = true
  enable_cluster_autoscaler = var.enable_cluster_autoscaler
  create_storage_class      = true
  storage_class_name        = var.storage_class

  providers = {
    aws        = aws
    tls        = tls
    helm       = helm
    kubernetes = kubernetes
  }
}

module "rds" {
  source = "./modules/rds"

  name       = var.db_identifier
  use_aurora = var.use_aurora

  # --- Aurora-only (read when use_aurora = true) ---
  engine_cluster                = "aurora-postgresql"
  engine_version_cluster        = "16"
  parameter_group_family_aurora = "aurora-postgresql16"
  aurora_instance_count         = 2

  # --- RDS-only (read when use_aurora = false) ---
  engine                     = "postgres"
  engine_version             = "16"
  parameter_group_family_rds = "postgres16"
  allocated_storage          = 20
  storage_type               = "gp2"

  # --- Common ---
  instance_class = var.db_instance_class
  db_name        = var.db_name
  username       = var.db_username
  password       = var.db_password

  vpc_id             = module.vpc.vpc_id
  subnet_private_ids = module.vpc.private_subnet_ids
  subnet_public_ids  = module.vpc.public_subnet_ids

  publicly_accessible = false

  # No CIDR ingress by default: the only way in is the EKS node security group.
  allowed_cidr_blocks        = var.db_allowed_cidr_blocks
  allowed_security_group_ids = [module.eks.node_security_group_id]

  multi_az                = var.use_aurora
  backup_retention_period = var.db_backup_retention_period
  storage_encrypted       = true
  skip_final_snapshot     = true

  parameters = {
    max_connections = "100"
    log_statement   = "all"
    work_mem        = "4096"
  }

  tags = {
    Environment = var.environment
    Project     = local.project
  }
}

resource "kubernetes_namespace" "app" {
  metadata {
    name = var.app_namespace

    labels = {
      name      = var.app_namespace
      ManagedBy = "Terraform"
    }
  }

  depends_on = [module.eks]
}

# The RDS endpoint and password only exist after apply, so they go into a Secret
# the chart mounts with envFrom instead of being committed to Git.
resource "kubernetes_secret" "app_database" {
  metadata {
    name      = var.app_db_secret_name
    namespace = kubernetes_namespace.app.metadata[0].name

    labels = {
      app       = "django-app"
      ManagedBy = "Terraform"
    }
  }

  type = "Opaque"

  data = {
    POSTGRES_HOST     = module.rds.endpoint
    POSTGRES_PORT     = tostring(module.rds.port)
    POSTGRES_DB       = module.rds.db_name
    POSTGRES_USER     = module.rds.username
    POSTGRES_PASSWORD = module.rds.password
  }
}

# Installed before Argo CD: the Django chart ships a ServiceMonitor, and its CRD
# comes with this stack.
module "monitoring" {
  source = "./modules/monitoring"

  namespace              = var.monitoring_namespace
  grafana_admin_user     = var.grafana_admin_user
  grafana_admin_password = var.grafana_admin_password
  grafana_service_type   = var.grafana_service_type
  storage_class          = var.storage_class
  prometheus_retention   = var.prometheus_retention
  app_namespace          = var.app_namespace

  providers = {
    helm       = helm
    kubernetes = kubernetes
  }

  depends_on = [module.eks]
}

module "jenkins" {
  source = "./modules/jenkins"

  admin_user     = var.jenkins_admin_user
  admin_password = var.jenkins_admin_password

  oidc_provider_arn  = module.eks.oidc_provider_arn
  oidc_provider_url  = module.eks.oidc_provider_url
  ecr_repository_arn = module.ecr.repository_arn
  storage_class      = var.storage_class

  git_repo_url = local.git_repo_url
  git_branch   = var.github_branch
  github_owner = var.github_owner
  github_token = var.github_token
  jenkinsfile  = var.jenkinsfile_path

  providers = {
    helm       = helm
    kubernetes = kubernetes
    aws        = aws
  }

  depends_on = [module.eks]
}

module "argo_cd" {
  source = "./modules/argo_cd"

  git_repo_url          = local.git_repo_url
  target_revision       = var.github_branch
  chart_path            = var.chart_path
  destination_namespace = var.app_namespace

  providers = {
    helm       = helm
    kubernetes = kubernetes
  }

  depends_on = [
    module.eks,
    module.monitoring,
    kubernetes_secret.app_database,
  ]
}
