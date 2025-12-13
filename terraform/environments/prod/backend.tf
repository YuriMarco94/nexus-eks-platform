terraform {
  backend "s3" {
    bucket         = "nexus-terraform-state-prod"
    key            = "eks-cluster/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks-prod"
    profile        = "nexus-prod"
  }
}