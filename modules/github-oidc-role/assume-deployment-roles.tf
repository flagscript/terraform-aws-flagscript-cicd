# Optional assume role inline policy
data "aws_iam_policy_document" "assume_role_policy_document" {
  count = local.create_assume_role_policy ? 1 : 0
  statement {
    actions = [
      "sts:AssumeRole",
      "sts:TagSession",
    ]
    effect    = "Allow"
    resources = var.allowed_assume_role_arns
  }
}

resource "aws_iam_role_policy" "assume_role_policy" {
  count  = local.create_assume_role_policy ? 1 : 0
  name   = "${var.role_prefix}AssumeRolePolicy"
  role   = aws_iam_role.github_oidc_role.name
  policy = data.aws_iam_policy_document.assume_role_policy_document[0].json
}
