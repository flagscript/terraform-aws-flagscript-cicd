/**
 * # KMS replicated example
 *
 * A primary state bucket in `us-east-1` and a backup bucket in `us-west-2`, encrypted with
 * a multi-region KMS key from the cicd-kms submodule.
 *
 * The cicd-kms submodule creates the primary key in `us-east-1`, a replica in `us-west-2`,
 * and the alias `alias/example-tfstate` in both regions. Its `key_arns` output is passed
 * straight to `bucket_encryption_keys`, which makes the root module:
 *
 * - set SSE-KMS (with an S3 bucket key) as the default encryption on each bucket
 * - opt the replication rule in to SSE-KMS objects and re-encrypt replicas with the
 *   `us-west-2` replica key
 * - grant the replication role `kms:Decrypt` on the primary key and `kms:Encrypt` /
 *   `kms:GenerateDataKey` on the replica key, scoped to S3 and these buckets
 * - add `kms:Decrypt`, `kms:DescribeKey` and `kms:GenerateDataKey` on both keys to the
 *   state access policy
 *
 * The cicd-kms key policy lets IAM policies in the account grant use of the key, which is
 * what the root module relies on.
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

module "state_key" {
  source  = "flagscript/flagscript-cicd/aws//modules/cicd-kms"
  version = "~> 1.0"

  key_name            = "example-tfstate"
  primary_region      = local.primary_region
  replica_regions     = [local.secondary_region]
  enable_key_rotation = true

  tags = {
    Environment = "example"
  }
}

module "cicd" {
  source  = "flagscript/flagscript-cicd/aws"
  version = "~> 1.0"

  primary_region      = local.primary_region
  secondary_region    = local.secondary_region
  state_bucket_prefix = "example"

  bucket_encryption_keys = module.state_key.key_arns

  tags = {
    Environment = "example"
  }
}
