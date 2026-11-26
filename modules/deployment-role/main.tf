# Deployment role
data "aws_iam_policy_document" "deployment_role_assume_role_policy_document" {
  statement {
    actions = [
      "sts:AssumeRole",
      "sts:SetSourceIdentity",
      "sts:TagSession",
    ]
    effect = "Allow"

    condition {
      test     = "StringEquals"
      values   = [local.organization_id]
      variable = "aws:PrincipalOrgID"
    }

    principals {
      type        = "AWS"
      identifiers = var.trusted_assume_role_arns
    }
  }
}


resource "aws_iam_role" "deployment_role" {
  assume_role_policy   = data.aws_iam_policy_document.deployment_role_assume_role_policy_document.json
  description          = "${var.role_prefix} IAM role for deployment."
  name                 = "${var.role_prefix}DeploymentRole"
  permissions_boundary = local.use_permissions_boundary ? data.aws_iam_policy.permissions_boundary_policy[0].arn : null
  tags = merge(
    local.common_tags,
    {
      "Name" = "${var.role_prefix}DeploymentRole"
    }
  )
}

# Optional inline policy attachment
resource "aws_iam_role_policy" "deployment_role_inline_policy" {
  count  = var.inline_policy_json_document != null ? 1 : 0
  name   = "${var.role_prefix}DeploymentRoleInlinePolicy"
  policy = var.inline_policy_json_document
  role   = aws_iam_role.deployment_role.name
}

# Optional managed policy attachments
resource "aws_iam_role_policy_attachment" "deployment_role_policy_attachment" {
  for_each   = var.managed_policy_arns
  role       = aws_iam_role.deployment_role.name
  policy_arn = each.value
}
