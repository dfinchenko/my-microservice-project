# ---- vpc module ----
output "vpc_id" {
  description = "ID of the VPC."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = module.vpc.private_subnet_ids
}

# ---- rds module ----
output "db_is_aurora" {
  description = "True when the RDS module created an Aurora cluster instead of a standard instance."
  value       = module.rds.is_aurora
}

output "db_identifier" {
  description = "Identifier of the Aurora cluster or of the RDS instance."
  value       = module.rds.identifier
}

output "db_endpoint" {
  description = "Writer hostname of the database."
  value       = module.rds.endpoint
}

output "db_reader_endpoint" {
  description = "Read-only hostname: the Aurora reader endpoint, or null for a single RDS instance."
  value       = module.rds.reader_endpoint
}

output "db_port" {
  description = "Port the database listens on."
  value       = module.rds.port
}

output "db_name" {
  description = "Name of the initial database."
  value       = module.rds.db_name
}

output "db_username" {
  description = "Master username of the database."
  value       = module.rds.username
}

output "db_password" {
  description = "Master password. Read with: terraform output -raw db_password"
  value       = module.rds.password
  sensitive   = true
}

output "db_connection_url" {
  description = "Ready-made connection URL. Read with: terraform output -raw db_connection_url"
  value       = module.rds.connection_url
  sensitive   = true
}

output "db_engine" {
  description = "Engine and version actually deployed."
  value       = "${module.rds.engine} ${module.rds.engine_version}"
}

output "db_security_group_id" {
  description = "Security group guarding the database."
  value       = module.rds.security_group_id
}

output "db_subnet_group_name" {
  description = "DB subnet group the database runs in."
  value       = module.rds.db_subnet_group_name
}

output "db_parameter_group_name" {
  description = "Parameter group applied to the database."
  value       = module.rds.parameter_group_name
}
