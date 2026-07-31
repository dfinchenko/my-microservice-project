# use_aurora = true. The cluster owns the data (six copies across three AZs),
# the instances are compute attached to it: one writer plus read-only replicas.

locals {
  # aurora_instance_count is the total, so readers are what is left after the writer.
  aurora_reader_count = var.aurora_replica_count != null ? var.aurora_replica_count : max(0, var.aurora_instance_count - 1)
}

resource "aws_rds_cluster" "aurora" {
  count = var.use_aurora ? 1 : 0

  cluster_identifier = "${var.name}-cluster"
  engine             = var.engine_cluster
  engine_version     = var.engine_version_cluster

  database_name   = var.db_name
  master_username = var.username
  master_password = local.master_password
  port            = local.port

  db_subnet_group_name            = aws_db_subnet_group.this.name
  vpc_security_group_ids          = [aws_security_group.this.id]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora[0].name

  storage_encrypted = var.storage_encrypted
  kms_key_id        = var.kms_key_id

  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = var.preferred_backup_window
  preferred_maintenance_window = var.preferred_maintenance_window

  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.name}-final-snapshot"
  apply_immediately         = var.apply_immediately

  tags = merge(local.tags, { Name = "${var.name}-cluster" })
}

# promotion_tier 0 makes the writer the first candidate after a failover.
resource "aws_rds_cluster_instance" "aurora_writer" {
  count = var.use_aurora ? 1 : 0

  identifier         = "${var.name}-writer"
  cluster_identifier = aws_rds_cluster.aurora[0].id
  engine             = aws_rds_cluster.aurora[0].engine
  engine_version     = aws_rds_cluster.aurora[0].engine_version
  instance_class     = var.instance_class

  db_subnet_group_name = aws_db_subnet_group.this.name
  publicly_accessible  = var.publicly_accessible
  promotion_tier       = 0

  performance_insights_enabled = var.performance_insights_enabled
  auto_minor_version_upgrade   = var.auto_minor_version_upgrade
  apply_immediately            = var.apply_immediately

  tags = merge(local.tags, { Name = "${var.name}-writer", Role = "writer" })

  lifecycle {
    precondition {
      condition     = !var.multi_az || local.aurora_reader_count >= 1
      error_message = "multi_az = true on Aurora needs at least one reader in a second AZ: set aurora_instance_count >= 2 (or aurora_replica_count >= 1)."
    }
  }
}

# Readers serve the cluster reader endpoint and are the failover targets.
resource "aws_rds_cluster_instance" "aurora_readers" {
  count = var.use_aurora ? local.aurora_reader_count : 0

  identifier         = "${var.name}-reader-${count.index}"
  cluster_identifier = aws_rds_cluster.aurora[0].id
  engine             = aws_rds_cluster.aurora[0].engine
  engine_version     = aws_rds_cluster.aurora[0].engine_version
  instance_class     = var.instance_class

  db_subnet_group_name = aws_db_subnet_group.this.name
  publicly_accessible  = var.publicly_accessible
  promotion_tier       = count.index + 1

  performance_insights_enabled = var.performance_insights_enabled
  auto_minor_version_upgrade   = var.auto_minor_version_upgrade
  apply_immediately            = var.apply_immediately

  tags = merge(local.tags, { Name = "${var.name}-reader-${count.index}", Role = "reader" })
}
