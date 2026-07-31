module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = "denys-finchenko-tf-state-lesson-db-module"
  table_name  = "terraform-locks-lesson-db-module"
}

module "vpc" {
  source             = "./modules/vpc"
  vpc_name           = "lesson-db-module-vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
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

  publicly_accessible = var.db_publicly_accessible

  # Inside the VPC by default; db_allowed_cidr_blocks opens it wider.
  allowed_cidr_blocks = concat([module.vpc.vpc_cidr_block], var.db_allowed_cidr_blocks)

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
    Environment = "dev"
    Project     = "lesson-db-module"
  }
}
