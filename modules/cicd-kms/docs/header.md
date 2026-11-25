# cicd-kms

Submodule that creates a customer-managed, multi-region KMS key for a CI/CD account: a primary key in one region and replicas of it in others, all with the same alias.

Its `key_arns` output is a map of region to key ARN, which is the shape the [root module's](https://github.com/flagscript/terraform-aws-flagscript-cicd) `bucket_encryption_keys` input expects. Pass it straight through to encrypt the Terraform state bucket(s) with your own key.

## Features

- **Multi-region symmetric key** (`SYMMETRIC_DEFAULT`, `ENCRYPT_DECRYPT`) in `primary_region`.
- **Replica keys** in each of `replica_regions`. Replicas share the primary's key material and key ID, so data encrypted in one region can be decrypted in another.
- **Same alias everywhere.** `alias/<key_name>` points to the key in every region.
- **IAM-managed access.** The key policy lets IAM policies in the account grant use of the key, so access is controlled with IAM rather than by editing the key policy. The root module's state access policy grants the KMS permissions Terraform needs.
- **Optional automatic rotation** through `enable_key_rotation`. It's set on the primary and applies to every replica.

## Usage

```hcl
module "state_key" {
  source  = "flagscript/flagscript-cicd/aws//modules/cicd-kms"
  version = "~> 1.0"

  key_name            = "example-tfstate"
  primary_region      = "us-east-1"
  replica_regions     = ["us-west-2"]
  enable_key_rotation = true
}

module "cicd" {
  source  = "flagscript/flagscript-cicd/aws"
  version = "~> 1.0"

  primary_region      = "us-east-1"
  secondary_region    = "us-west-2"
  state_bucket_prefix = "example"

  bucket_encryption_keys = module.state_key.key_arns
}
```

The key ARNs and IDs are in the `key_arns` and `key_ids` outputs, keyed by region (for example `module.state_key.key_arns["us-west-2"]`).

### Notes

- **Naming:** `key_name` may contain only lowercase letters and hyphens. It names the alias and is used in the key description. Changing it replaces the aliases but keeps the keys.
- **Regions:** `replica_regions` can't contain `primary_region` or the same region twice (enforced by validation). To use the key with the root module's backup bucket, include `secondary_region` in `replica_regions`.
- **Deleting keys:** removing a region from `replica_regions`, changing `primary_region`, or destroying the module schedules the affected keys for deletion after `deletion_window_in_days` (7–30 days, 30 by default). Once a key is deleted, anything encrypted with it can't be decrypted, including old state versions. You can cancel a scheduled deletion in the KMS console or with `aws kms cancel-key-deletion` during the waiting period.
- **Disabling the key:** setting `enable_key = false` disables the primary and all replicas. Terraform can't read or write state encrypted with a disabled key until it's enabled again.
- **Rotation:** `enable_key_rotation` is `false` by default. Turning it on is recommended. KMS then rotates the key material every year and keeps the old material, so existing objects still decrypt.
- **Cost:** each replica is billed as its own KMS key.
