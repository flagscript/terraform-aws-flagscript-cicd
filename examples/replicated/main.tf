/**
 * # Replicated example
 *
 * A primary state bucket in `us-east-1` and a backup bucket in `us-west-2`, both encrypted
 * with SSE-S3.
 *
 * Setting `secondary_region` makes the module:
 *
 * - create a second bucket with the same versioning, encryption, public access block and
 *   TLS bucket policy as the primary
 * - add a one-way replication rule from the primary to the backup, including delete markers
 * - create an IAM role that S3 assumes to replicate, scoped to these two buckets
 * - include both buckets in the state access policy
 *
 * Keep backends pointed at the primary bucket. The backup is a disaster-recovery copy.
 *
 * ```bash
 * terraform init
 * terraform apply
 * ```
 */

provider "aws" {
  region = "us-east-1"
}

module "cicd" {
  source  = "flagscript/flagscript-cicd/aws"
  version = "~> 1.0"

  primary_region      = "us-east-1"
  secondary_region    = "us-west-2"
  state_bucket_prefix = "example"

  tags = {
    Environment = "example"
  }
}
