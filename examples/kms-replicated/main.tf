/**
 * # KMS replicated example
 *
 * A primary state bucket in `us-east-1` and a backup bucket in `us-west-2`, where each
 * bucket is encrypted with a customer-managed KMS key in its own region.
 *
 * Passing `bucket_encryption_keys` makes the module:
 *
 * - set SSE-KMS (with an S3 bucket key) as the default encryption on each bucket
 * - opt the replication rule in to SSE-KMS objects and re-encrypt replicas with the
 *   backup-region key
 * - grant the replication role `kms:Decrypt` on the primary key and `kms:Encrypt` /
 *   `kms:GenerateDataKey` on the backup key, scoped to S3 and these buckets
 * - add `kms:Decrypt`, `kms:DescribeKey` and `kms:GenerateDataKey` on both keys to the
 *   state access policy
 *
 * The module grants KMS use through IAM policies, so each key policy must let IAM policies
 * in the account grant access. This example's key policy does that with the standard
 * account-root statement.
 *
 * ```bash
 * terraform init
 * terraform apply
 * ```
 */

provider "aws" {
  region = "us-east-1"
}

locals {
  primary_region   = "us-east-1"
  secondary_region = "us-west-2"
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

# Key policy: let IAM policies in this account grant use of the key.
data "aws_iam_policy_document" "state_key_policy" {
  statement {
    sid       = "EnableAccountAdministration"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

resource "aws_kms_key" "state" {
  for_each = toset([local.primary_region, local.secondary_region])
  region   = each.key

  description         = "Terraform state encryption key (${each.key})"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.state_key_policy.json
}

module "cicd" {
  source  = "flagscript/flagscript-cicd/aws"
  version = "~> 1.0"

  primary_region      = local.primary_region
  secondary_region    = local.secondary_region
  state_bucket_prefix = "example"

  bucket_encryption_keys = {
    for region, key in aws_kms_key.state : region => key.arn
  }

  tags = {
    Environment = "example"
  }
}
