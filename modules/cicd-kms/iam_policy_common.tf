data "aws_iam_policy_document" "account_use_policy_document" {
  statement {
    actions   = ["kms:*"]
    resources = ["*"]
    sid       = "KmsAccountIam"

    principals {
      type        = "AWS"
      identifiers = ["arn:${local.current_partition}:iam::${local.current_account_id}:root"]
    }
  }
}
