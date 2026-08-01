# module.s3_backend cannot keep its own state in the bucket it creates:
#
#   1. terraform init
#   2. terraform apply -target=module.s3_backend
#   3. uncomment the block below
#   4. terraform init -migrate-state
#   5. terraform apply
#
# On the way out, reverse steps 4 and 3 before destroying the bucket.
#
terraform {
  backend "s3" {
    bucket         = "denys-finchenko-tf-state-final-project"
    key            = "final-project/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks-final-project"
    encrypt        = true
  }
}
