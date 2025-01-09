locals {
  project = "terraform-aws-k8s-cluster"

  default_tags = {
    Project = local.project
    Label   = "Thesis"
  }

  github_url = "https://github.com/suhejlvejseli"

  github_repos = [
    {
      name = "suhejlvejseli/terraform-aws-k8s-cluster"
      policy = {
        Version = "2012-10-17",
        Statement = [
          {
            Action = [
              "vpc:*",
              "ec2:*",
              "iam:*",
            ]
            Effect   = "Allow"
            Resource = "*"
          },
          {
            Action = [
              "s3:PutObject",
              "s3:Describe*",
              "s3:Get*",
              "s3:List*",
              "s3:CreateBucket",
              "s3:PutBucketOwnershipControls",
              "s3:PutBucketAcl",
              "s3:DeleteBucket"
            ]
            Effect   = "Allow"
            Resource = "*"
          },
          {
            Action = [
              "dynamodb:Describe*",
              "dynamodb:Get*",
              "dynamodb:PutItem",
              "dynamodb:DeleteItem",
              "dynamodb:UpdateItem"
            ]
            Effect   = "Allow"
            Resource = "arn:aws:dynamodb:eu-central-1:116981781406:table/terraform-aws-k8s-cluster-terraform-lock"
          }
        ]
      }
    }
  ]
}

resource "aws_iam_openid_connect_provider" "github" {
  client_id_list  = [local.github_url, "sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.tfc_certificate.certificates[0].sha1_fingerprint]
  url             = "https://token.actions.githubusercontent.com"

  tags = local.default_tags
}

resource "aws_iam_role" "this" {
  for_each = { for t in local.github_repos : t.name => t }

  name                 = "github-${split("/", each.value.name)[1]}-role"
  assume_role_policy   = data.aws_iam_policy_document.assume_role[each.key].json
  description          = "Role assumed by the GitHub OIDC provider"
  max_session_duration = 3600
  path                 = "/"
}

resource "aws_iam_policy" "this" {
  for_each = { for t in local.github_repos : t.name => t }

  name        = "github-${split("/", each.value.name)[1]}-policy"
  description = "Policy for the GitHub role"
  path        = "/"
  policy      = jsonencode(each.value.policy)
}

resource "aws_iam_policy_attachment" "this" {
  for_each = { for t in local.github_repos : t.name => t }

  name       = "github-${split("/", each.value.name)[1]}-attachment"
  roles      = [aws_iam_role.this[each.key].name]
  policy_arn = aws_iam_policy.this[each.key].arn
}