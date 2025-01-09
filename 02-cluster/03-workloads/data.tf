data "terraform_remote_state" "networking" {
  backend = "s3"

  config = {
    bucket = "terraform-aws-k8s-cluster-terraform-state"
    key    = "02-cluster/02-networking/terraform.tfstate"
    region = "eu-central-1"
    dynamodb_table = "terraform-aws-k8s-cluster-terraform-lock"
  }
}