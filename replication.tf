# IAM role S3 assumes to replicate
data "aws_iam_policy_document" "s3_assume_role_policy_document" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}

# Replication role for S3 to assume in order to replicate objects to the secondary region
resource "aws_iam_role" "terraform_state_replication_role" {
  count              = local.enable_replication ? 1 : 0
  assume_role_policy = data.aws_iam_policy_document.s3_assume_role_policy_document.json
  description        = "Terraform state replication role for ${var.state_bucket_prefix} terraform state bucket from ${var.primary_region} to ${var.secondary_region}."
  name               = "${local.state_bucket_prefix_title}TfStateReplicationRole"
  tags = merge(
    local.common_tags,
    {
      "Name" = "${local.state_bucket_prefix_title}TfStateReplicationRole"
    },
  )
}

# Replication policy
data "aws_iam_policy_document" "terraform_state_replication_policy_document" {
  count = local.enable_replication ? 1 : 0
  # Read replication config / list the source
  statement {
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
    ]
    effect = "Allow"
    resources = [
      aws_s3_bucket.terraform_state_bucket[var.primary_region].arn
    ]
  }

  # Read object versions from the source
  statement {
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
    ]
    effect = "Allow"
    resources = [
      "${aws_s3_bucket.terraform_state_bucket[var.primary_region].arn}/*"
    ]
  }

  # Write replicas into the destination
  statement {
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
    ]
    resources = [
      "${aws_s3_bucket.terraform_state_bucket[var.secondary_region].arn}/*"
    ]
  }

  # Decrypt source objects
  dynamic "statement" {
    for_each = contains(keys(var.bucket_encryption_keys), var.primary_region) ? [true] : []
    content {
      actions = [
        "kms:Decrypt"
      ]
      effect    = "Allow"
      resources = [var.bucket_encryption_keys[var.primary_region]]
      condition {
        test     = "StringLike"
        variable = "kms:ViaService"
        values   = ["s3.${var.primary_region}.amazonaws.com"]
      }
      condition {
        test     = "StringLike"
        variable = "kms:EncryptionContext:aws:s3:arn"
        values = [
          aws_s3_bucket.terraform_state_bucket[var.primary_region].arn,        # bucket key is enabled
          "${aws_s3_bucket.terraform_state_bucket[var.primary_region].arn}/*", # when it isn't
        ]
      }
    }
  }

  # Encrypt replicas in the destination
  dynamic "statement" {
    for_each = contains(keys(var.bucket_encryption_keys), var.secondary_region) ? [true] : []
    content {
      actions   = ["kms:Encrypt", "kms:GenerateDataKey"]
      resources = [var.bucket_encryption_keys[var.secondary_region]]
      condition {
        test     = "StringLike"
        variable = "kms:ViaService"
        values   = ["s3.${var.secondary_region}.amazonaws.com"]
      }
      condition {
        test     = "StringLike"
        variable = "kms:EncryptionContext:aws:s3:arn"
        values = [
          aws_s3_bucket.terraform_state_bucket[var.secondary_region].arn,        # bucket key is enabled
          "${aws_s3_bucket.terraform_state_bucket[var.secondary_region].arn}/*", # when it isn't
        ]
      }
    }
  }
}

resource "aws_iam_role_policy" "terraform_state_replication_policy" {
  count  = local.enable_replication ? 1 : 0
  name   = "${var.state_bucket_prefix}-s3-replication"
  role   = aws_iam_role.terraform_state_replication_role[0].id
  policy = data.aws_iam_policy_document.terraform_state_replication_policy_document[0].json
}

# Replication config (only on the primary = one-way)
resource "aws_s3_bucket_replication_configuration" "distribution_replication_primary_to_secondary" {
  depends_on = [ # Versioning and encryption must be enabled before the replication config is applied
    aws_s3_bucket_versioning.terraform_state_bucket_versioning,
    aws_s3_bucket_server_side_encryption_configuration.terraform_state_bucket_encryption
  ]

  count  = local.enable_replication ? 1 : 0
  region = var.primary_region
  bucket = aws_s3_bucket.terraform_state_bucket[var.primary_region].id
  role   = aws_iam_role.terraform_state_replication_role[0].arn

  rule {
    id     = "replicate-all"
    status = "Enabled"

    delete_marker_replication { status = "Enabled" }

    filter {} # empty filter = whole bucket (use prefix/tag to narrow)

    destination {
      bucket        = aws_s3_bucket.terraform_state_bucket[var.secondary_region].arn
      storage_class = "STANDARD" # or STANDARD_IA / GLACIER_IR to save cost on the DR copy

      # key in the destination region used to re-encrypt replicas
      dynamic "encryption_configuration" {
        for_each = contains(keys(var.bucket_encryption_keys), var.secondary_region) ? [true] : []
        content {
          replica_kms_key_id = var.bucket_encryption_keys[var.secondary_region]
        }
      }
    }

    # opt in to replicating SSE-KMS objects
    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = contains(keys(var.bucket_encryption_keys), var.primary_region) ? "Enabled" : "Disabled"
      }
    }

  }
}
