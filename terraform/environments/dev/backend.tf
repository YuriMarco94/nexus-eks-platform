terraform {
  backend "s3" {
    bucket         = "nexus-597088058179-terraform-state-dev"
    key            = "eks-cluster/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks-dev-597088058179"
  }
}
