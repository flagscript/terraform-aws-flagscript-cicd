<!-- BEGIN_TF_DOCS -->
# Basic example

A single Terraform state bucket in `us-east-1`, encrypted with SSE-S3, plus the IAM
policy that grants access to it.

```bash
terraform init
terraform apply
```

Point other configurations at the bucket from the `terraform_state_bucket_name` output:

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