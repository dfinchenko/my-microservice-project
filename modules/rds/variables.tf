# ---------------------------------------------------------------------------
# Identity
# ---------------------------------------------------------------------------

variable "name" {
  description = "Base name of the database. Used as the RDS instance identifier (or the Aurora cluster identifier) and as the prefix for the subnet group, security group and parameter groups."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,40}$", var.name))
    error_message = "name must start with a lowercase letter and contain only lowercase letters, digits and hyphens (max 41 chars)."
  }
}

# ---------------------------------------------------------------------------
# Deployment mode — the switch the whole module is built around
# ---------------------------------------------------------------------------

variable "use_aurora" {
  description = "false -> a single aws_db_instance + aws_db_parameter_group. true -> an aws_rds_cluster with aurora_instance_count members + aws_rds_cluster_parameter_group. The subnet group and the security group are created in both cases."
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------
# Engine — the *_cluster variables are read only when use_aurora = true
# ---------------------------------------------------------------------------

variable "engine" {
  description = "Engine for the standard RDS instance: postgres, mysql, mariadb, ... Ignored when use_aurora = true."
  type        = string
  default     = "postgres"

  validation {
    condition     = !startswith(var.engine, "aurora")
    error_message = "engine is for the standard RDS instance only. Set an Aurora engine in engine_cluster and flip use_aurora = true."
  }
}

variable "engine_version" {
  description = "Version of the standard RDS engine. A major version alone (\"16\") lets AWS pick the latest minor; \"16.4\" pins it. Ignored when use_aurora = true."
  type        = string
  default     = "16"
}

variable "engine_cluster" {
  description = "Engine for the Aurora cluster: aurora-postgresql or aurora-mysql. Ignored when use_aurora = false."
  type        = string
  default     = "aurora-postgresql"

  validation {
    condition     = contains(["aurora-postgresql", "aurora-mysql"], var.engine_cluster)
    error_message = "engine_cluster must be aurora-postgresql or aurora-mysql."
  }
}

variable "engine_version_cluster" {
  description = "Version of the Aurora engine, e.g. \"16.4\" for aurora-postgresql. Ignored when use_aurora = false."
  type        = string
  default     = "16"
}

# ---------------------------------------------------------------------------
# Sizing
# ---------------------------------------------------------------------------

variable "instance_class" {
  description = "Instance class for the RDS instance or for every Aurora cluster member. Aurora does not support db.t3.micro — use db.t4g.medium or larger there."
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Storage in GiB for the standard RDS instance. Aurora grows its storage automatically, so this is ignored when use_aurora = true."
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Upper bound in GiB for RDS storage autoscaling. 0 disables autoscaling. Ignored when use_aurora = true."
  type        = number
  default     = 0
}

variable "storage_type" {
  description = "Storage type of the standard RDS instance: gp2, gp3, io1, io2. Ignored when use_aurora = true."
  type        = string
  default     = "gp3"
}

variable "aurora_instance_count" {
  description = "Number of Aurora cluster members. The first one is the writer, the rest are readers (promotion_tier follows the index). 1 = writer only. Ignored when use_aurora = false."
  type        = number
  default     = 2

  validation {
    condition     = var.aurora_instance_count >= 1
    error_message = "aurora_instance_count must be at least 1 — a cluster always needs its writer."
  }
}

variable "aurora_replica_count" {
  description = "Explicit number of Aurora reader instances, overriding the aurora_instance_count - 1 default. null keeps the two variables in sync. Ignored when use_aurora = false."
  type        = number
  default     = null
}

variable "read_replica_count" {
  description = "Number of read replicas of the standard RDS instance. Requires backup_retention_period > 0. Ignored when use_aurora = true (use aurora_instance_count instead)."
  type        = number
  default     = 0
}

# ---------------------------------------------------------------------------
# Credentials and initial database
# ---------------------------------------------------------------------------

variable "db_name" {
  description = "Name of the database created inside the instance/cluster."
  type        = string
  default     = "appdb"
}

variable "username" {
  description = "Master username."
  type        = string
  default     = "dbadmin"
}

variable "password" {
  description = "Master password (min 8 chars). Leave null and the module generates one — read it back with: terraform output -raw db_password. Pass via TF_VAR_* rather than committing it."
  type        = string
  sensitive   = true
  default     = null

  validation {
    condition     = var.password == null || length(coalesce(var.password, "")) >= 8
    error_message = "password must be at least 8 characters long."
  }
}

# ---------------------------------------------------------------------------
# Network
# ---------------------------------------------------------------------------

variable "vpc_id" {
  description = "VPC the security group is created in. Must be the VPC that owns the subnets below."
  type        = string
}

variable "subnet_private_ids" {
  description = "Private subnet IDs. Used by the DB subnet group when publicly_accessible = false. At least two subnets in two AZs are required."
  type        = list(string)
  default     = []
}

variable "subnet_public_ids" {
  description = "Public subnet IDs. Used by the DB subnet group when publicly_accessible = true. At least two subnets in two AZs are required."
  type        = list(string)
  default     = []
}

variable "publicly_accessible" {
  description = "false -> the database gets a private address and lands in subnet_private_ids. true -> it gets a public address and lands in subnet_public_ids."
  type        = bool
  default     = false
}

variable "port" {
  description = "TCP port the database listens on. null derives it from the engine: 5432 for PostgreSQL, 3306 for MySQL/MariaDB."
  type        = number
  default     = null
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to reach the database port. Empty means no CIDR-based ingress at all — the module never opens 0.0.0.0/0 for you."
  type        = list(string)
  default     = []
}

variable "allowed_security_group_ids" {
  description = "Security groups allowed to reach the database port, e.g. the EKS node security group. Preferred over allowed_cidr_blocks for in-VPC clients."
  type        = list(string)
  default     = []
}

# ---------------------------------------------------------------------------
# Parameter groups
# ---------------------------------------------------------------------------

variable "parameter_group_family_rds" {
  description = "Family of the DB parameter group, must match engine + major version: postgres16, mysql8.0, ... null derives it from engine and engine_version."
  type        = string
  default     = null
}

variable "parameter_group_family_aurora" {
  description = "Family of the DB cluster parameter group: aurora-postgresql16, aurora-mysql8.0, ... null derives it from engine_cluster and engine_version_cluster."
  type        = string
  default     = null
}

variable "parameters" {
  description = "Parameters written into the parameter group (DB parameter group for RDS, DB cluster parameter group for Aurora). The defaults are PostgreSQL parameters — override the whole map for MySQL."
  type        = map(string)
  default = {
    max_connections = "100"
    log_statement   = "all"
    work_mem        = "4096"
  }
}

variable "parameters_apply_method" {
  description = "Per-parameter apply method, overriding default_apply_method. Static parameters such as max_connections only accept pending-reboot; dynamic ones such as work_mem also accept immediate."
  type        = map(string)
  default = {
    log_statement = "immediate"
    work_mem      = "immediate"
  }

  validation {
    condition     = alltrue([for m in values(var.parameters_apply_method) : contains(["immediate", "pending-reboot"], m)])
    error_message = "apply method must be immediate or pending-reboot."
  }
}

variable "default_apply_method" {
  description = "Apply method for parameters not listed in parameters_apply_method."
  type        = string
  default     = "pending-reboot"

  validation {
    condition     = contains(["immediate", "pending-reboot"], var.default_apply_method)
    error_message = "default_apply_method must be immediate or pending-reboot."
  }
}

# ---------------------------------------------------------------------------
# Availability, backup, maintenance
# ---------------------------------------------------------------------------

variable "multi_az" {
  description = "Standard RDS: creates a standby in a second AZ. Aurora: storage is already replicated across three AZs, so this only asks the module to spread cluster members over the subnet AZs (set aurora_instance_count >= 2 for a real failover target)."
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Days automated backups are kept. 0 disables them (and read replicas along with them)."
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_period >= 0 && var.backup_retention_period <= 35
    error_message = "backup_retention_period must be between 0 and 35."
  }
}

variable "preferred_backup_window" {
  description = "Daily UTC window for automated backups, e.g. 03:00-04:00."
  type        = string
  default     = "03:00-04:00"
}

variable "preferred_maintenance_window" {
  description = "Weekly UTC maintenance window, e.g. sun:04:30-sun:05:30."
  type        = string
  default     = "sun:04:30-sun:05:30"
}

variable "auto_minor_version_upgrade" {
  description = "Let AWS apply minor engine upgrades during the maintenance window."
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Apply changes right away instead of waiting for the maintenance window. Can cause a short outage."
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------
# Data protection
# ---------------------------------------------------------------------------

variable "storage_encrypted" {
  description = "Encrypt storage at rest."
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ARN for storage encryption. null uses the default aws/rds key."
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "Block terraform destroy / console deletion of the database."
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip the final snapshot on destroy. false keeps a snapshot named <name>-final-snapshot, which is what you want whenever the data matters."
  type        = bool
  default     = true
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights. Not supported on db.t3.micro / db.t2 classes."
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------
# Tags
# ---------------------------------------------------------------------------

variable "tags" {
  description = "Tags applied to every resource the module creates."
  type        = map(string)
  default     = {}
}
