# ---- s3-backend module ----
output "s3_bucket_name" {
  description = "Name of the S3 bucket storing Terraform state."
  value       = module.s3_backend.s3_bucket_name
}

output "s3_bucket_url" {
  description = "Regional URL of the S3 state bucket."
  value       = module.s3_backend.s3_bucket_url
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB state-lock table."
  value       = module.s3_backend.dynamodb_table_name
}

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

# ---- ecr module ----
output "ecr_repository_url" {
  description = "URL of the ECR repository."
  value       = module.ecr.repository_url
}
