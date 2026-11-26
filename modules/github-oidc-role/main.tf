# Github oidc role
data "aws_iam_policy_document" "github_oidc_assume_role_policy_document" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = var.github_repository_paths
    }

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github_oidc_provider.arn]
    }
  }
}

resource "aws_iam_role" "github_oidc_role" {
  assume_role_policy = data.aws_iam_policy_document.github_oidc_assume_role_policy_document.json
  description        = "${var.role_prefix} IAM role for GitHub OIDC authentication to AWS."
  name               = "${var.role_prefix}GithubOidcRole"
  tags = merge(
    local.common_tags,
    {
      "Name" = "${var.role_prefix}GithubOidcRole"
    }
  )
}

# Attach additional policies to the role
resource "aws_iam_role_policy_attachment" "github_oidc_role_policy_attachment" {
  for_each   = var.managed_policy_arns
  role       = aws_iam_role.github_oidc_role.name
  policy_arn = each.value
}
