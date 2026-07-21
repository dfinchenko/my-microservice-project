# Bootstrap order (see README):
#   1. terraform init                              # local state
#   2. terraform apply -target=module.s3_backend   # create the bucket + lock table
#   3. uncomment the block below
#   4. terraform init -migrate-state               # move state into S3
#
# terraform {
#   backend "s3" {
#     bucket         = "denys-finchenko-tf-state-lesson-7"
#     key            = "lesson-7/terraform.tfstate"
#     region         = "us-west-2"
#     dynamodb_table = "terraform-locks-lesson-7"
#     encrypt        = true
#   }
# }
