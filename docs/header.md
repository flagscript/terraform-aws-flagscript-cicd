# terraform-aws-flagscript-cicd

Terraform module that creates an S3 bucket for Terraform remote state in a CI/CD account, following reasonable AWS defaults. It can also keep a replicated backup bucket in a second region, and it creates an IAM policy that grants access to the state bucket(s).

Three submodules round out a CI/CD setup:

- [cicd-kms](https://github.com/flagscript/terraform-aws-flagscript-cicd/tree/main/modules/cicd-kms) creates a multi-region KMS key to encrypt the state bucket(s) with.
- [github-oidc-role](https://github.com/flagscript/terraform-aws-flagscript-cicd/tree/main/modules/github-oidc-role) lets GitHub Actions workflows assume a role that can read and write state, with no long-lived AWS keys.
- [deployment-role](https://github.com/flagscript/terraform-aws-flagscript-cicd/tree/main/modules/deployment-role) creates a role in each workload account that the GitHub Actions role assumes to deploy there.

## Features

- **State bucket** in the S3 account-regional namespace, named `<state_bucket_prefix>-tfstate-<account_id>-<region>-an`.
- **Versioning always on**, so every state write can be recovered.
- **Locked down by default.** Public access is fully blocked, and the bucket policy denies requests that don't use TLS 1.2 or later.
- **Encryption by default.** SSE-S3 is used unless you pass customer-managed KMS keys per region through `bucket_encryption_keys`, such as the `key_arns` output of the cicd-kms submodule. SSE-C is blocked.
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

### Encrypting with KMS

Use the cicd-kms submodule to create a multi-region key with a replica in the backup region, and pass its `key_arns` output to `bucket_encryption_keys`:

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

Buckets encrypted with a KMS key don't need a `kms_key_id` in the backend block, because the bucket's default encryption applies.

### Granting access

Attach the `terraform_state_bucket_access_policy_arn` output to the roles or users that run Terraform. With the github-oidc-role submodule:

```hcl
module "github_role" {
  source  = "flagscript/flagscript-cicd/aws//modules/github-oidc-role"
  version = "~> 1.0"

  role_prefix             = "Example"
  github_repository_paths = ["repo:example-org/example-repo:ref:refs/heads/main"]

  managed_policy_arns = {
    tfstate = module.cicd.terraform_state_bucket_access_policy_arn
  }
}
```

`managed_policy_arns` is keyed by names you choose, so it plans even though the policy is created in the same apply.

### Deploying to workload accounts

Keep state and the GitHub Actions role in the CI/CD account, and give each workload account a deployment role the GitHub Actions role can assume. The deployment-role submodule trusts the CI/CD role, and github-oidc-role's `allowed_assume_role_arns` lets the CI/CD role assume it. The CI/CD and workload accounts must be in the same AWS Organization:

```hcl
module "github_role" {
  source  = "flagscript/flagscript-cicd/aws//modules/github-oidc-role"
  version = "~> 1.0"

  role_prefix             = "Example"
  github_repository_paths = ["repo:example-org/app:ref:refs/heads/main"]

  managed_policy_arns = {
    tfstate = module.cicd.terraform_state_bucket_access_policy_arn
  }

  allowed_assume_role_arns = [module.deployment_role.deployment_role_arn]
}

module "deployment_role" {
  source  = "flagscript/flagscript-cicd/aws//modules/deployment-role"
  version = "~> 1.0"

  providers = {
    aws = aws.workload
  }

  role_prefix              = "Example"
  trusted_assume_role_arns = [module.github_role.github_oidc_role_arn]

  managed_policy_arns = {
    power_user = "arn:aws:iam::aws:policy/PowerUserAccess"
  }
}
```

Terraform then reads and writes state as the GitHub Actions role in the CI/CD account, and makes changes as the deployment role in the workload account.

### Notes

- **Naming:** `state_bucket_prefix` may contain only lowercase letters and hyphens, and must be at most 24 characters so bucket names stay within the 63-character S3 limit. It's also turned into a title-cased prefix for IAM names (for example `example-ci` becomes `ExampleCi`, giving `ExampleCiTfStateAccessPolicy`).
- **Renaming:** changing `state_bucket_prefix` or a region replaces the bucket(s). Buckets are created with `force_destroy = false`, so Terraform won't delete a bucket that still holds state. Move your state first.
- **Same-account access:** the access policy is an identity policy, so it grants access to principals in the CI/CD account. Principals in other accounts would also need a bucket policy that allows them, which this module doesn't create. To deploy into other accounts, keep state access with the CI/CD role and chain to a deployment role (see above).
- **Backup bucket:** the secondary bucket is a disaster-recovery copy filled by replication. Keep backends pointed at the primary. Replication is asynchronous, and it only copies objects written **after** it's enabled. Use S3 Batch Replication to backfill a backup bucket added to an existing state bucket.
- **KMS keys:** with a secondary region, `bucket_encryption_keys` must have keys for **both** regions or **neither** (enforced by validation). The secondary-region key re-encrypts replicas. Each key policy must let IAM policies in the account grant access, because the module grants KMS use through IAM. Both the default key policy and the cicd-kms submodule's key policy do.

## Submodules

- [cicd-kms](https://github.com/flagscript/terraform-aws-flagscript-cicd/tree/main/modules/cicd-kms): customer-managed multi-region KMS key with replicas and a shared alias, whose `key_arns` output plugs into `bucket_encryption_keys`
- [github-oidc-role](https://github.com/flagscript/terraform-aws-flagscript-cicd/tree/main/modules/github-oidc-role): IAM role that GitHub Actions workflows assume through the GitHub OIDC provider, limited to the repositories, branches or environments you list, with managed policies attached, and optionally allowed to assume deployment roles in other accounts
- [deployment-role](https://github.com/flagscript/terraform-aws-flagscript-cicd/tree/main/modules/deployment-role): IAM role in a workload account, trusted by CI/CD roles, with managed policies, an optional inline policy and an optional permissions boundary

## Examples

- [basic](https://github.com/flagscript/terraform-aws-flagscript-cicd/tree/main/examples/basic): single-region state bucket
- [replicated](https://github.com/flagscript/terraform-aws-flagscript-cicd/tree/main/examples/replicated): primary and backup state buckets with replication
- [kms-replicated](https://github.com/flagscript/terraform-aws-flagscript-cicd/tree/main/examples/kms-replicated): replication with a multi-region KMS key from the cicd-kms submodule
- [github-actions](https://github.com/flagscript/terraform-aws-flagscript-cicd/tree/main/examples/github-actions): complete CI/CD account: KMS-encrypted, replicated state bucket plus a GitHub Actions OIDC role that can use it
- [cross-account](https://github.com/flagscript/terraform-aws-flagscript-cicd/tree/main/examples/cross-account): CI/CD account with state and a GitHub Actions role, plus a deployment role in a workload account that the GitHub Actions role assumes
