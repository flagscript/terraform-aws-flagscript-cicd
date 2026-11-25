<!-- BEGIN_TF_DOCS -->
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

## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.16 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.72 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.72 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_kms_alias.primary_kms_key_alias](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_alias.replica_kms_key_alias](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.primary_kms_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_key_policy.primary_kms_key_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key_policy) | resource |
| [aws_kms_key_policy.replica_kms_key_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key_policy) | resource |
| [aws_kms_replica_key.replica_kms_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_replica_key) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_key_name"></a> [key\_name](#input\_key\_name) | The name of the KMS key. | `string` | n/a | yes |
| <a name="input_primary_region"></a> [primary\_region](#input\_primary\_region) | Region of the primary key. | `string` | n/a | yes |
| <a name="input_deletion_window_in_days"></a> [deletion\_window\_in\_days](#input\_deletion\_window\_in\_days) | The waiting period, specified in number of days. | `number` | `30` | no |
| <a name="input_enable_key"></a> [enable\_key](#input\_enable\_key) | Specifies whether the cicd key is enabled. | `bool` | `true` | no |
| <a name="input_enable_key_rotation"></a> [enable\_key\_rotation](#input\_enable\_key\_rotation) | Specifies whether key rotation is enabled. | `bool` | `false` | no |
| <a name="input_replica_regions"></a> [replica\_regions](#input\_replica\_regions) | List of regions to create replica keys in. | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to merge into module tags. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_key_arns"></a> [key\_arns](#output\_key\_arns) | Map of regions to their respective cicd kms key arns. |
| <a name="output_key_ids"></a> [key\_ids](#output\_key\_ids) | Map of regions to their respective cicd kms key ids. |

## Contributing

Commits follow [Conventional Commits](https://www.conventionalcommits.org/), which commitlint enforces through lefthook. Releases and the changelog are generated by semantic-release when changes merge to `main`.

The documentation tables above are generated by [terraform-docs](https://terraform-docs.io/) on pre-commit. To change the surrounding text, edit `docs/header.md` or `docs/footer.md` (or `modules/<name>/docs/header.md` for a submodule), not this README.

## License

MIT licensed. See [LICENSE](https://github.com/flagscript/terraform-aws-flagscript-cicd/blob/main/LICENSE).
<!-- END_TF_DOCS -->