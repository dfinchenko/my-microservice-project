# use_aurora = false. multi_az here is a standby in a second AZ: it serves no
# traffic, it only takes over on failure.

resource "aws_db_instance" "standard" {
  count = var.use_aurora ? 0 : 1

  identifier     = var.name
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  db_name  = var.db_name
  username = var.username
  password = local.master_password
  port     = local.port

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage > 0 ? var.max_allocated_storage : null
  storage_type          = var.storage_type
  storage_encrypted     = var.storage_encrypted
  kms_key_id            = var.kms_key_id

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]
  parameter_group_name   = aws_db_parameter_group.standard[0].name
  publicly_accessible    = var.publicly_accessible
  multi_az               = var.multi_az

  backup_retention_period    = var.backup_retention_period
  backup_window              = var.preferred_backup_window
  maintenance_window         = var.preferred_maintenance_window
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  apply_immediately          = var.apply_immediately

  performance_insights_enabled = var.performance_insights_enabled
  deletion_protection          = var.deletion_protection
  skip_final_snapshot          = var.skip_final_snapshot
  final_snapshot_identifier    = var.skip_final_snapshot ? null : "${var.name}-final-snapshot"

  tags = merge(local.tags, { Name = var.name })

  lifecycle {
    precondition {
      condition     = var.read_replica_count == 0 || var.backup_retention_period > 0
      error_message = "Read replicas require automated backups: set backup_retention_period > 0."
    }
  }
}

# Replicas inherit engine, storage and credentials from the source instance.
resource "aws_db_instance" "replica" {
  count = var.use_aurora ? 0 : var.read_replica_count

  identifier          = "${var.name}-replica-${count.index}"
  replicate_source_db = aws_db_instance.standard[0].identifier
  instance_class      = var.instance_class

  vpc_security_group_ids = [aws_security_group.this.id]
  parameter_group_name   = aws_db_parameter_group.standard[0].name
  publicly_accessible    = var.publicly_accessible

  auto_minor_version_upgrade   = var.auto_minor_version_upgrade
  apply_immediately            = var.apply_immediately
  performance_insights_enabled = var.performance_insights_enabled
  skip_final_snapshot          = true

  tags = merge(local.tags, { Name = "${var.name}-replica-${count.index}", Role = "reader" })
}
