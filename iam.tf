data "aws_iam_policy_document" "terraform_state_bucket_access_policy_document" {
  statement {
    actions = [
      "s3:ListBucket",
    ]
    effect    = "Allow"
    resources = [for bucket in aws_s3_bucket.terraform_state_bucket : bucket.arn]
    sid       = "AllowTerraformStateBucketList"
  }

  statement {
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject",
    ]
    effect = "Allow"
    resources = flatten([
      for bucket in aws_s3_bucket.terraform_state_bucket : [bucket.arn, "${bucket.arn}/*"]
    ])
    sid = "AllowTerraformStateBucketAccess"
  }

  dynamic "statement" {
    for_each = length(var.bucket_encryption_keys) > 0 ? [true] : []
    content {
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:GenerateDataKey",
      ]
      effect    = "Allow"
      resources = values(var.bucket_encryption_keys)
      sid       = "AllowTerraformStateBucketKMSAccess"
    }
  }
}

resource "aws_iam_policy" "terraform_state_bucket_access_policy" {
  description = "Policy to allow access to the ${var.state_bucket_prefix} terraform state bucket."
  name        = "${local.state_bucket_prefix_title}TfStateAccessPolicy"
  policy      = data.aws_iam_policy_document.terraform_state_bucket_access_policy_document.json

  tags = merge(
    local.common_tags,
    {
      "Name" = "${local.state_bucket_prefix_title}TfStateAccessPolicy"
    },
  )
}
