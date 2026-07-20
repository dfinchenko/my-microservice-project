output "s3_bucket_name" {
  description = "Name of the S3 bucket that stores Terraform state files."
  value       = aws_s3_bucket.terraform_state.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 state bucket."
  value       = aws_s3_bucket.terraform_state.arn
}

output "s3_bucket_url" {
  description = "Regional domain name (URL) of the S3 state bucket."
  value       = aws_s3_bucket.terraform_state.bucket_regional_domain_name
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table used for state locking."
  value       = aws_dynamodb_table.terraform_locks.name
}
