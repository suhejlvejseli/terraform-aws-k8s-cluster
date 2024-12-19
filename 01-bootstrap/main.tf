locals {
  project = "terraform-aws-k8s-cluster"

  default_tags = {
    Project = local.project
    Label   = "Thesis"
  }
}

resource "aws_s3_bucket" "tf_state" {
  bucket = "${local.project}-terraform-state"

  tags = local.default_tags
}

resource "aws_s3_bucket_ownership_controls" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.tf_state]
}

resource "aws_dynamodb_table" "tf_lock_table" {
  name         = "${local.project}-terraform-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = local.default_tags
}