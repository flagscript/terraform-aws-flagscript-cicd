<!-- BEGIN_TF_DOCS -->
# Replicated example

A primary state bucket in `us-east-1` and a backup bucket in `us-west-2`, both encrypted
with SSE-S3.

Setting `secondary_region` makes the module:

- create a second bucket with the same versioning, encryption, public access block and
  TLS bucket policy as the primary
- add a one-way replication rule from the primary to the backup, including delete markers
- create an IAM role that S3 assumes to replicate, scoped to these two buckets
- include both buckets in the state access policy

Keep backends pointed at the primary bucket. The backup is a disaster-recovery copy.

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

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_terraform_state_bucket_access_policy_arn"></a> [terraform\_state\_bucket\_access\_policy\_arn](#output\_terraform\_state\_bucket\_access\_policy\_arn) | ARN of the policy that grants access to the Terraform state bucket(s). |
| <a name="output_terraform_state_bucket_name"></a> [terraform\_state\_bucket\_name](#output\_terraform\_state\_bucket\_name) | Regional map of Terraform state bucket names. |
<!-- END_TF_DOCS -->