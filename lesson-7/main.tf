# S3 + DynamoDB backend store (lesson-7-specific names to avoid colliding with lesson-5).
module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = "denys-finchenko-tf-state-lesson-7"
  table_name  = "terraform-locks-lesson-7"
}

# VPC (same network layout as lesson-5, plus EKS/ELB subnet tags).
module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  vpc_name           = "lesson-7-vpc"
  cluster_name       = "lesson-7-eks"
}

# ECR repository for the Django image.
module "ecr" {
  source       = "./modules/ecr"
  ecr_name     = "lesson-7-ecr"
  scan_on_push = true
}

# EKS cluster + managed node group.
module "eks" {
  source              = "./modules/eks"
  cluster_name        = "lesson-7-eks"
  kubernetes_version  = "1.30"
  subnet_ids          = concat(module.vpc.public_subnet_ids, module.vpc.private_subnet_ids)
  private_subnet_ids  = module.vpc.private_subnet_ids
  node_instance_types = ["t3.small"]
  node_desired_size   = 2
  node_min_size       = 2
  node_max_size       = 3
}
