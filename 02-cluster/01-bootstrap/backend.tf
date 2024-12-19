terraform {
  backend "s3" {
    bucket         = "terraform-aws-k8s-cluster-terraform-state"
    key            = "02-cluster/01-bootstrap/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-aws-k8s-cluster-terraform-lock"
  }
}