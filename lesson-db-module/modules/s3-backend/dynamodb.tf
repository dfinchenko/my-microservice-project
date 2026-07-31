# The hash key must be named "LockID" — required by the Terraform S3 backend.
resource "aws_dynamodb_table" "terraform_locks" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = var.table_name
    Environment = "shared"
    ManagedBy   = "Terraform"
    Purpose     = "terraform-state-lock"
  }
}
