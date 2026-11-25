<!-- BEGIN_TF_DOCS -->
# KMS replicated example

A primary state bucket in `us-east-1` and a backup bucket in `us-west-2`, encrypted with
a multi-region KMS key from the cicd-kms submodule.

The cicd-kms submodule creates the primary key in `us-east-1`, a replica in `us-west-2`,
and the alias `alias/example-tfstate` in both regions. Its `key_arns` output is passed
straight to `bucket_encryption_keys`, which makes the root module:

- set SSE-KMS (with an S3 bucket key) as the default encryption on each bucket
- opt the replication rule in to SSE-KMS objects and re-encrypt replicas with the
  `us-west-2` replica key
- grant the replication role `kms:Decrypt` on the primary key and `kms:Encrypt` /
  `kms:GenerateDataKey` on the replica key, scoped to S3 and these buckets
- add `kms:Decrypt`, `kms:DescribeKey` and `kms:GenerateDataKey` on both keys to the
  state access policy

The cicd-kms key policy lets IAM policies in the account grant use of the key, which is
what the root module relies on.

```bash
terraform init
terraform apply
```

## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.16 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.72 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_cicd"></a> [cicd](#module\_cicd) | flagscript/flagscript-cicd/aws | ~> 1.0 |
| <a name="module_state_key"></a> [state\_key](#module\_state\_key) | flagscript/flagscript-cicd/aws//modules/cicd-kms | ~> 1.0 |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_key_arns"></a> [key\_arns](#output\_key\_arns) | Regional map of KMS key ARNs used to encrypt the state buckets. |
| <a name="output_terraform_state_bucket_access_policy_arn"></a> [terraform\_state\_bucket\_access\_policy\_arn](#output\_terraform\_state\_bucket\_access\_policy\_arn) | ARN of the policy that grants access to the Terraform state bucket(s). |
| <a name="output_terraform_state_bucket_name"></a> [terraform\_state\_bucket\_name](#output\_terraform\_state\_bucket\_name) | Regional map of Terraform state bucket names. |
<!-- END_TF_DOCS -->