variable "aws_region" {
  description = "AWS region where all resources are created."
  type        = string
  default     = "us-east-1"
}

# ---- rds module ----

variable "use_aurora" {
  description = "false -> a single PostgreSQL RDS instance, true -> an Aurora PostgreSQL cluster with a writer and a reader. Flipping this is the only change needed to switch database types."
  type        = bool
  default     = false
}

variable "db_identifier" {
  description = "Base name of the database: RDS instance identifier, or Aurora cluster identifier plus the -cluster suffix."
  type        = string
  default     = "lesson-db-module-db"
}

variable "db_instance_class" {
  description = "Instance class of the database. db.t3.micro is free-tier eligible for RDS; Aurora needs db.t4g.medium or larger."
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Name of the database created inside the instance/cluster."
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master username of the database."
  type        = string
  default     = "dbadmin"
}

variable "db_password" {
  description = "Master password. Leave null and Terraform generates one; read it back with: terraform output -raw db_password. Pass via TF_VAR_db_password."
  type        = string
  sensitive   = true
  default     = null
}

variable "db_backup_retention_period" {
  description = "Days automated backups are kept. Free-tier accounts are capped at 1 — anything higher fails with FreeTierRestrictionError. The module itself defaults to 7."
  type        = number
  default     = 1
}

variable "db_publicly_accessible" {
  description = "true gives the database a public address and moves it into the public subnets. Only useful together with db_allowed_cidr_blocks."
  type        = bool
  default     = false
}

variable "db_allowed_cidr_blocks" {
  description = "Extra CIDR blocks allowed to reach the database on top of the VPC itself, e.g. [\"203.0.113.10/32\"] to connect with psql from your machine."
  type        = list(string)
  default     = []
}
