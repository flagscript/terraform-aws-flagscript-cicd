# terraform-aws-flagscript-cicd

Terraform module that creates an S3 bucket for Terraform remote state in a CI/CD account, following reasonable AWS defaults. It can also keep a replicated backup bucket in a second region, and it creates an IAM policy that grants access to the state bucket(s).

Pair it with the [github-oidc-role](https://github.com/flagscript/terraform-aws-flagscript-cicd/tree/main/modules/github-oidc-role) submodule to let GitHub Actions workflows assume a role that can read and write state, with no long-lived AWS keys.

## Features

- **State bucket** in the S3 account-regional namespace, named `<state_bucket_prefix>-tfstate-<account_id>-<region>-an`.
- **Versioning always on**, so every state write can be recovered.
- **Locked down by default.** Public access is fully blocked, and the bucket policy denies requests that don't use TLS 1.2 or later.
- **Encryption by default.** SSE-S3 is used unless you pass customer-managed KMS keys per region through `bucket_encryption_keys`. SSE-C is blocked.
- **Optional backup region.** Set `secondary_region` to create a second bucket and replicate one way from the primary, including delete markers. Replication of KMS-encrypted objects is configured automatically.
- **Access policy** (`<PrefixTitle>TfStateAccessPolicy`) that grants list, read, write and delete on the state bucket(s), plus KMS use when keys are set. This is everything the S3 backend needs, including S3-native state locking (`use_lockfile`).
- **EventBridge notifications** are enabled on every bucket.

## Usage

```hcl
provider "aws" {
  region = "us-east-1"
}

module "cicd" {
  source  = "flagscript/flagscript-cicd/aws"
  version = "~> 1.0"

  primary_region      = "us-east-1"
  state_bucket_prefix = "example"

  # Optional: replicated backup bucket in a second region
  secondary_region = "us-west-2"
}
```

Then point other configurations at the primary bucket:

```hcl
terraform {
  backend "s3" {
    bucket       = "example-tfstate-123456789012-us-east-1-an"
    key          = "my-project/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
```

The bucket name is also in the `terraform_state_bucket_name` output, keyed by region (for example `module.cicd.terraform_state_bucket_name["us-east-1"]`).

### Granting access

Attach the `terraform_state_bucket_access_policy_arn` output to the roles or users that run Terraform. With the github-oidc-role submodule:

```hcl
module "github_role" {
  source  = "flagscript/flagscript-cicd/aws//modules/github-oidc-role"
  version = "~> 1.0"

  role_prefix             = "Example"
  github_repository_paths = ["repo:example-org/example-repo:ref:refs/heads/main"]

  managed_policy_arns_to_attach = [
    module.cicd.terraform_state_bucket_access_policy_arn,
  ]
}
```

### Notes

- **Naming:** `state_bucket_prefix` may contain only lowercase letters and hyphens, and must be at most 24 characters so bucket names stay within the 63-character S3 limit. It's also turned into a title-cased prefix for IAM names (for example `example-ci` becomes `ExampleCi`, giving `ExampleCiTfStateAccessPolicy`).
- **Renaming:** changing `state_bucket_prefix` or a region replaces the bucket(s). Buckets are created with `force_destroy = false`, so Terraform won't delete a bucket that still holds state. Move your state first.
- **Same-account access:** the access policy is an identity policy, so it grants access to principals in the CI/CD account. Principals in other accounts would also need a bucket policy that allows them, which this module doesn't create.
- **Backup bucket:** the secondary bucket is a disaster-recovery copy filled by replication. Keep backends pointed at the primary. Replication is asynchronous, and it only copies objects written **after** it's enabled. Use S3 Batch Replication to backfill a backup bucket added to an existing state bucket.
- **KMS keys:** with a secondary region, `bucket_encryption_keys` must have keys for **both** regions or **neither** (enforced by validation). The secondary-region key re-encrypts replicas. Each key policy must let IAM policies in the account grant access (the default key policy does), because the module grants KMS use through IAM.

## Submodules

- [github-oidc-role](https://github.com/flagscript/terraform-aws-flagscript-cicd/tree/main/modules/github-oidc-role): IAM role that GitHub Actions workflows assume through the GitHub OIDC provider, limited to the repositories, branches or environments you list, with managed policies attached

## Examples

- [basic](https://github.com/flagscript/terraform-aws-flagscript-cicd/tree/main/examples/basic): single-region state bucket
- [replicated](https://github.com/flagscript/terraform-aws-flagscript-cicd/tree/main/examples/replicated): primary and backup state buckets with replication
- [kms-replicated](https://github.com/flagscript/terraform-aws-flagscript-cicd/tree/main/examples/kms-replicated): replication with customer-managed KMS keys in each region
- [github-actions](https://github.com/flagscript/terraform-aws-flagscript-cicd/tree/main/examples/github-actions): state bucket plus a GitHub Actions OIDC role that can use it
