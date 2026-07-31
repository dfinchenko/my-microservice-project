# Resources created in both modes.

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

locals {
  engine         = var.use_aurora ? var.engine_cluster : var.engine
  engine_version = var.use_aurora ? var.engine_version_cluster : var.engine_version

  is_mysql = length(regexall("mysql|mariadb", local.engine)) > 0

  # Families: postgres16 for PostgreSQL, mysql8.0 for MySQL.
  version_parts  = split(".", local.engine_version)
  family_version = local.is_mysql ? join(".", slice(local.version_parts, 0, min(2, length(local.version_parts)))) : local.version_parts[0]

  parameter_group_family = var.use_aurora ? coalesce(var.parameter_group_family_aurora, "${var.engine_cluster}${local.family_version}") : coalesce(var.parameter_group_family_rds, "${var.engine}${local.family_version}")

  port = coalesce(var.port, local.is_mysql ? 3306 : 5432)

  # A public database needs subnets with a route to the IGW.
  subnet_ids = var.publicly_accessible ? var.subnet_public_ids : var.subnet_private_ids

  master_password = var.password != null ? var.password : one(random_password.master[*].result)

  tags = merge(var.tags, { ManagedBy = "Terraform" })
}

resource "random_password" "master" {
  count = var.password == null ? 1 : 0

  length  = 24
  special = true
  # RDS rejects / @ " and spaces.
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_db_subnet_group" "this" {
  name        = "${var.name}-subnet-group"
  description = "Subnet group for ${var.name}"
  subnet_ids  = local.subnet_ids

  tags = merge(local.tags, { Name = "${var.name}-subnet-group" })

  lifecycle {
    precondition {
      condition     = length(local.subnet_ids) >= 2
      error_message = "RDS needs at least two subnets in two different AZs. Populate ${var.publicly_accessible ? "subnet_public_ids (publicly_accessible = true)" : "subnet_private_ids"}."
    }
  }
}

resource "aws_security_group" "this" {
  name        = "${var.name}-sg"
  description = "Access to ${var.name} on port ${local.port}"
  vpc_id      = var.vpc_id

  tags = merge(local.tags, { Name = "${var.name}-sg" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "cidr" {
  for_each = toset(var.allowed_cidr_blocks)

  security_group_id = aws_security_group.this.id
  description       = "Database access from ${each.value}"
  cidr_ipv4         = each.value
  from_port         = local.port
  to_port           = local.port
  ip_protocol       = "tcp"

  tags = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "security_group" {
  for_each = toset(var.allowed_security_group_ids)

  security_group_id            = aws_security_group.this.id
  description                  = "Database access from ${each.value}"
  referenced_security_group_id = each.value
  from_port                    = local.port
  to_port                      = local.port
  ip_protocol                  = "tcp"

  tags = local.tags
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.this.id
  description       = "Allow all outbound"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"

  tags = local.tags
}

resource "aws_db_parameter_group" "standard" {
  count = var.use_aurora ? 0 : 1

  name_prefix = "${var.name}-rds-"
  family      = local.parameter_group_family
  description = "Parameter group for ${var.name} (${local.parameter_group_family})"

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name         = parameter.key
      value        = parameter.value
      apply_method = lookup(var.parameters_apply_method, parameter.key, var.default_apply_method)
    }
  }

  tags = merge(local.tags, { Name = "${var.name}-rds-params" })

  # Changing the engine version replaces the group: create the new one first.
  lifecycle {
    create_before_destroy = true
  }
}

# Aurora keeps parameters on the cluster, so every member inherits them.
resource "aws_rds_cluster_parameter_group" "aurora" {
  count = var.use_aurora ? 1 : 0

  name_prefix = "${var.name}-aurora-"
  family      = local.parameter_group_family
  description = "Cluster parameter group for ${var.name} (${local.parameter_group_family})"

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name         = parameter.key
      value        = parameter.value
      apply_method = lookup(var.parameters_apply_method, parameter.key, var.default_apply_method)
    }
  }

  tags = merge(local.tags, { Name = "${var.name}-aurora-params" })

  lifecycle {
    create_before_destroy = true
  }
}
