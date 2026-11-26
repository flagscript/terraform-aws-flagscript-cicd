<!-- BEGIN_TF_DOCS -->
# Cross-account example

GitHub Actions deploying into a workload account from a central CI/CD account.

In the CI/CD account (`111111111111`), this example:

- creates the Terraform state bucket and its access policy with the root module
- creates `ExampleGithubOidcRole` with the github-oidc-role submodule, trusted by the
  `main` branch of one repository, with the state access policy attached and permission
  to assume the deployment role

In the workload account (`222222222222`), it:

- creates `ExampleDeploymentRole` with the deployment-role submodule, trusted by the
  GitHub Actions role, with the AWS-managed `PowerUserAccess` policy and an inline policy
  created in this configuration

The two role modules refer to each other's outputs, and Terraform orders the work
itself: the GitHub Actions role first, then the deployment role, then the policy that
lets the GitHub Actions role assume it.

The CI/CD account must already have the GitHub OIDC identity provider. The `workload`
provider reaches the workload account by assuming `OrganizationAccountAccessRole`, which
AWS Organizations creates in accounts it creates. Use any role you can assume there.

```bash
terraform init
terraform apply
```

Then, in a workflow, assume the GitHub Actions role and chain to the deployment role:

```yaml
permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
      - uses: aws-actions/configure-aws-credentials@v5
        with:
          role-to-assume: arn:aws:iam::111111111111:role/ExampleGithubOidcRole
          aws-region: us-east-1
      - uses: aws-actions/configure-aws-credentials@v5
        with:
          role-to-assume: arn:aws:iam::222222222222:role/ExampleDeploymentRole
          aws-region: us-east-1
          role-chaining: true
```

## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.16 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.72 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws.workload"></a> [aws.workload](#provider\_aws.workload) | >= 6.72 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_cicd"></a> [cicd](#module\_cicd) | flagscript/flagscript-cicd/aws | ~> 1.0 |
| <a name="module_deployment_role"></a> [deployment\_role](#module\_deployment\_role) | flagscript/flagscript-cicd/aws//modules/deployment-role | ~> 1.0 |
| <a name="module_github_role"></a> [github\_role](#module\_github\_role) | flagscript/flagscript-cicd/aws//modules/github-oidc-role | ~> 1.0 |

## Resources

| Name | Type |
| ---- | ---- |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_deployment_role_arn"></a> [deployment\_role\_arn](#output\_deployment\_role\_arn) | ARN of the deployment role in the workload account. |
| <a name="output_github_oidc_role_arn"></a> [github\_oidc\_role\_arn](#output\_github\_oidc\_role\_arn) | ARN of the role for GitHub Actions to assume in the CI/CD account. |
| <a name="output_terraform_state_bucket_name"></a> [terraform\_state\_bucket\_name](#output\_terraform\_state\_bucket\_name) | Regional map of Terraform state bucket names in the CI/CD account. |
<!-- END_TF_DOCS -->