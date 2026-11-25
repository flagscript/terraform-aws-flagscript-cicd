<!-- BEGIN_TF_DOCS -->
# GitHub Actions example

A complete CI/CD account setup: a KMS-encrypted, replicated Terraform state bucket, and an
IAM role that GitHub Actions workflows assume through OIDC to read and write that state.

This example:

- creates the GitHub OIDC identity provider for `token.actions.githubusercontent.com`.
  An account can have only one per URL, so remove this resource if your account already
  has it.
- creates a multi-region KMS key in `us-east-1` with a replica in `us-west-2`, using the
  cicd-kms submodule
- creates the state buckets, encrypted with that key, and the access policy with the
  root module. The access policy includes the KMS permissions the role needs.
- creates `ExampleGithubOidcRole` with the github-oidc-role submodule, trusted by the
  `main` branch and the `production` environment of one repository, and attaches the
  state access policy to it

The submodule looks up the OIDC provider, so `depends_on` makes that lookup wait until
the provider exists.

```bash
terraform init
terraform apply
```

Then assume the role from a workflow, using the `github_oidc_role_arn` output:

```yaml
permissions:
  id-token: write
  contents: read

jobs:
  plan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
      - uses: aws-actions/configure-aws-credentials@v5
        with:
          role-to-assume: arn:aws:iam::123456789012:role/ExampleGithubOidcRole
          aws-region: us-east-1
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
| <a name="module_github_role"></a> [github\_role](#module\_github\_role) | flagscript/flagscript-cicd/aws//modules/github-oidc-role | ~> 1.0 |
| <a name="module_state_key"></a> [state\_key](#module\_state\_key) | flagscript/flagscript-cicd/aws//modules/cicd-kms | ~> 1.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_iam_openid_connect_provider.github](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_github_oidc_role_arn"></a> [github\_oidc\_role\_arn](#output\_github\_oidc\_role\_arn) | ARN of the role for GitHub Actions to assume. |
| <a name="output_terraform_state_bucket_name"></a> [terraform\_state\_bucket\_name](#output\_terraform\_state\_bucket\_name) | Regional map of Terraform state bucket names. |
<!-- END_TF_DOCS -->