# Bootstrap order (see README):
#   1. terraform init                              # local state
#   2. terraform apply -target=module.s3_backend   # create the bucket + lock table
#   3. uncomment the block below
#   4. terraform init -migrate-state               # move state into S3
#
# terraform {
#   backend "s3" {
#     bucket         = "denys-finchenko-tf-state-lesson-8-9"
#     key            = "lesson-8-9/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "terraform-locks-lesson-8-9"
#     encrypt        = true
#   }
# }
