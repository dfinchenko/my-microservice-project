# one() resolves the zero/one-element resource lists, so every output works in
# both modes.

output "is_aurora" {
  description = "True when the module created an Aurora cluster, false when it created a standard RDS instance."
  value       = var.use_aurora
}

output "identifier" {
  description = "Identifier of the Aurora cluster or of the RDS instance."
  value       = var.use_aurora ? one(aws_rds_cluster.aurora[*].cluster_identifier) : one(aws_db_instance.standard[*].identifier)
}

output "arn" {
  description = "ARN of the Aurora cluster or of the RDS instance."
  value       = var.use_aurora ? one(aws_rds_cluster.aurora[*].arn) : one(aws_db_instance.standard[*].arn)
}

output "endpoint" {
  description = "Hostname to write to: the Aurora writer endpoint or the RDS instance address. Always points at the current primary, including after a failover."
  value       = var.use_aurora ? one(aws_rds_cluster.aurora[*].endpoint) : one(aws_db_instance.standard[*].address)
}

output "reader_endpoint" {
  description = "Hostname for read-only traffic: the Aurora reader endpoint (load-balanced across readers), or the first RDS read replica. null when there is nothing to read from."
  value       = var.use_aurora ? one(aws_rds_cluster.aurora[*].reader_endpoint) : try(aws_db_instance.replica[0].address, null)
}

output "replica_endpoints" {
  description = "Addresses of every reader: Aurora reader instances or standard RDS read replicas."
  value       = var.use_aurora ? aws_rds_cluster_instance.aurora_readers[*].endpoint : aws_db_instance.replica[*].address
}

output "port" {
  description = "TCP port the database listens on."
  value       = local.port
}

output "db_name" {
  description = "Name of the initial database."
  value       = var.db_name
}

output "username" {
  description = "Master username."
  value       = var.username
}

output "password" {
  description = "Master password — the one passed in, or the generated one. Read with: terraform output -raw db_password"
  value       = local.master_password
  sensitive   = true
}

output "connection_url" {
  description = "Ready-made connection URL for the writer endpoint."
  value       = "${local.is_mysql ? "mysql" : "postgresql"}://${var.username}:${local.master_password}@${var.use_aurora ? one(aws_rds_cluster.aurora[*].endpoint) : one(aws_db_instance.standard[*].address)}:${local.port}/${var.db_name}"
  sensitive   = true
}

output "engine" {
  description = "Engine actually deployed — engine_cluster or engine, depending on use_aurora."
  value       = local.engine
}

output "engine_version" {
  description = "Engine version actually deployed."
  value       = var.use_aurora ? one(aws_rds_cluster.aurora[*].engine_version_actual) : one(aws_db_instance.standard[*].engine_version_actual)
}

output "security_group_id" {
  description = "ID of the database security group. Reference it from client security groups."
  value       = aws_security_group.this.id
}

output "db_subnet_group_name" {
  description = "Name of the DB subnet group."
  value       = aws_db_subnet_group.this.name
}

output "parameter_group_name" {
  description = "Name of the parameter group in use: the DB cluster parameter group for Aurora, the DB parameter group for standard RDS."
  value       = var.use_aurora ? one(aws_rds_cluster_parameter_group.aurora[*].name) : one(aws_db_parameter_group.standard[*].name)
}

output "parameter_group_family" {
  description = "Family the parameter group was created with — useful to confirm the derived value matches the engine version."
  value       = local.parameter_group_family
}
