# TF State bucket
## Use account-regional namespace
resource "aws_s3_bucket" "terraform_state_bucket" {
  for_each         = toset(local.deployment_regions)
  region           = each.key
  bucket           = "${var.state_bucket_prefix}-tfstate-${local.current_account_id}-${each.key}-an"
  bucket_namespace = "account-regional"
  force_destroy    = false
  tags = merge(
    local.common_tags,
    {
      "Name" = "${var.state_bucket_prefix}-tfstate-${local.current_account_id}-${each.key}-an"
    },
  )
}

## Public access block
resource "aws_s3_bucket_public_access_block" "terraform_state_bucket_public_access_block" {
  for_each                = toset(local.deployment_regions)
  region                  = each.key
  bucket                  = aws_s3_bucket.terraform_state_bucket[each.key].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

## Always enable versioning
resource "aws_s3_bucket_versioning" "terraform_state_bucket_versioning" {
  for_each = toset(local.deployment_regions)
  region   = each.key
  bucket   = aws_s3_bucket.terraform_state_bucket[each.key].id
  versioning_configuration {
    mfa_delete = "Disabled"
    status     = "Enabled"
  }
}

## Bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_bucket_encryption" {
  for_each = toset(local.deployment_regions)
  region   = each.key
  bucket   = aws_s3_bucket.terraform_state_bucket[each.key].id
  rule {
    blocked_encryption_types = ["SSE-C"]
    bucket_key_enabled       = true
    apply_server_side_encryption_by_default {
      kms_master_key_id = contains(keys(var.bucket_encryption_keys), each.key) ? var.bucket_encryption_keys[each.key] : null
      sse_algorithm     = contains(keys(var.bucket_encryption_keys), each.key) ? "aws:kms" : "AES256"
    }
  }
}

## Enabled eventbridge notifications
resource "aws_s3_bucket_notification" "terraform_state_bucket_notifications" {
  for_each    = toset(local.deployment_regions)
  region      = each.key
  bucket      = aws_s3_bucket.terraform_state_bucket[each.key].id
  eventbridge = true
}

# Terraform state bucket policy
data "aws_iam_policy_document" "terraform_state_bucket_policy_document" {
  for_each = toset(local.deployment_regions)
  # 1. Require TLS
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.terraform_state_bucket[each.key].arn,
      "${aws_s3_bucket.terraform_state_bucket[each.key].arn}/*",
    ]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  # 2. Require modern TLS (optional, but common)
  statement {
    sid     = "DenyOldTLS"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.terraform_state_bucket[each.key].arn,
      "${aws_s3_bucket.terraform_state_bucket[each.key].arn}/*",
    ]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "NumericLessThan"
      variable = "s3:TlsVersion"
      values   = ["1.2"]
    }
  }
}

resource "aws_s3_bucket_policy" "terraform_state_bucket_policy" {
  for_each = toset(local.deployment_regions)
  region   = each.key
  bucket   = aws_s3_bucket.terraform_state_bucket[each.key].id
  policy   = data.aws_iam_policy_document.terraform_state_bucket_policy_document[each.key].json
}
