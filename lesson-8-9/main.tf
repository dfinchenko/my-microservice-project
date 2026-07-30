locals {
  git_repo_url = "https://github.com/${var.github_owner}/${var.github_repo}.git"
}

module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = "denys-finchenko-tf-state-lesson-8-9"
  table_name  = "terraform-locks-lesson-8-9"
}

module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  vpc_name           = "lesson-8-9-vpc"
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
  kubernetes_version = "1.34"
  node_ami_type      = "AL2023_x86_64_STANDARD"

  subnet_ids         = concat(module.vpc.public_subnet_ids, module.vpc.private_subnet_ids)
  private_subnet_ids = module.vpc.private_subnet_ids

  node_instance_types = ["m7i-flex.large"]
  node_desired_size   = 2
  node_min_size       = 2
  node_max_size       = 3
}

module "jenkins" {
  source = "./modules/jenkins"

  admin_user     = var.jenkins_admin_user
  admin_password = var.jenkins_admin_password

  oidc_provider_arn  = module.eks.oidc_provider_arn
  oidc_provider_url  = module.eks.oidc_provider_url
  ecr_repository_arn = module.ecr.repository_arn
  storage_class      = var.jenkins_storage_class

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

  git_repo_url    = local.git_repo_url
  target_revision = var.github_branch
  chart_path      = var.chart_path

  providers = {
    helm       = helm
    kubernetes = kubernetes
  }

  depends_on = [module.eks]
}
