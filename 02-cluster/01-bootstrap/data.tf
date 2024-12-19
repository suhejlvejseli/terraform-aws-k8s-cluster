data "tls_certificate" "tfc_certificate" {
  url = "https://github.com"
}

data "aws_iam_policy_document" "assume_role" {
  for_each = { for t in local.github_repos : t.name => t }

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test = "StringLike"
      values = [
        "repo:${each.value.name}:*"
      ]
      variable = "token.actions.githubusercontent.com:sub"
    }


    condition {
      test = "StringLike"
      values = [
        "sts.amazonaws.com"
      ]
      variable = "token.actions.githubusercontent.com:aud"
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.github.arn]
      type        = "Federated"
    }
  }
}