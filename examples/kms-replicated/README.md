<!-- BEGIN_TF_DOCS -->
# KMS replicated example

A primary state bucket in `us-east-1` and a backup bucket in `us-west-2`, where each
bucket is encrypted with a customer-managed KMS key in its own region.

Passing `bucket_encryption_keys` makes the module:

- set SSE-KMS (with an S3 bucket key) as the default encryption on each bucket
- opt the replication rule in to SSE-KMS objects and re-encrypt replicas with the
  backup-region key
- grant the replication role `kms:Decrypt` on the primary key and `kms:Encrypt` /
  `kms:GenerateDataKey` on the backup key, scoped to S3 and these buckets
- add `kms:Decrypt`, `kms:DescribeKey` and `kms:GenerateDataKey` on both keys to the
  state access policy

The module grants KMS use through IAM policies, so each key policy must let IAM policies
in the account grant access. This example's key policy does that with the standard
account-root statement.

```bash
terraform init
terraform apply
```

## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.16 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.72 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.72 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_cicd"></a> [cicd](#module\_cicd) | flagscript/flagscript-cicd/aws | ~> 1.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_kms_key.state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_terraform_state_bucket_access_policy_arn"></a> [terraform\_state\_bucket\_access\_policy\_arn](#output\_terraform\_state\_bucket\_access\_policy\_arn) | ARN of the policy that grants access to the Terraform state bucket(s). |
| <a name="output_terraform_state_bucket_name"></a> [terraform\_state\_bucket\_name](#output\_terraform\_state\_bucket\_name) | Regional map of Terraform state bucket names. |
<!-- END_TF_DOCS -->