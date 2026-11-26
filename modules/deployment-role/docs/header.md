# deployment-role

Submodule that creates an IAM role in a workload account for CI/CD to deploy with. Roles in the CI/CD account, such as one created by the [github-oidc-role](https://github.com/flagscript/terraform-aws-flagscript-cicd/tree/main/modules/github-oidc-role) submodule, assume it to make changes in the workload account, so pipelines never need credentials stored for that account.

## Features

- **IAM role** named `<role_prefix>DeploymentRole`, trusted only by the role ARNs in `trusted_assume_role_arns`.
- **Same organization only.** The trust policy also requires `aws:PrincipalOrgID` to match the workload account's AWS Organization, so only callers from accounts in that organization can assume the role.
- **Session tags and source identity allowed.** The trust policy allows `sts:TagSession` and `sts:SetSourceIdentity` as well as `sts:AssumeRole`, so callers that tag their sessions, such as `aws-actions/configure-aws-credentials` with `role-chaining: true`, or that set a source identity, such as a Terraform provider `assume_role` block with `source_identity`, work without extra settings.
- **Managed policies** from `managed_policy_arns` are attached to the role, up to 10 (the default IAM quota per role).
- **Optional inline policy** from `inline_policy_json_document`, for permissions that only this role needs.
- **Optional permissions boundary**, looked up by name with `permissions_boundary_policy_name`, to cap what the role can do whatever policies it has.

## How it fits together

Access across accounts needs permission on both sides:

1. In the CI/CD account, github-oidc-role creates a role that GitHub Actions workflows assume through OIDC.
2. In the workload account, this submodule creates the deployment role and trusts the CI/CD role by passing its ARN in `trusted_assume_role_arns`.
3. Back in the CI/CD account, the deployment role's ARN goes into github-oidc-role's `allowed_assume_role_arns`, which lets the CI/CD role call `sts:AssumeRole` on it.

When both accounts are managed in one configuration (with a provider for each), Terraform works out this order itself. See the [cross-account](https://github.com/flagscript/terraform-aws-flagscript-cicd/tree/main/examples/cross-account) example.

## Usage

```hcl
provider "aws" {
  alias  = "workload"
  region = "us-east-1"

  assume_role {
    role_arn = "arn:aws:iam::222222222222:role/OrganizationAccountAccessRole"
  }
}

module "deployment_role" {
  source  = "flagscript/flagscript-cicd/aws//modules/deployment-role"
  version = "~> 1.0"

  providers = {
    aws = aws.workload
  }

  role_prefix = "Example"

  trusted_assume_role_arns = [
    "arn:aws:iam::111111111111:role/ExampleGithubOidcRole",
  ]

  managed_policy_arns = {
    power_user = "arn:aws:iam::aws:policy/PowerUserAccess"
  }
}
```

The role ARN is also in the `deployment_role_arn` output.

Then, in a workflow, assume the CI/CD role through OIDC and chain to the deployment role:

```yaml
permissions:
  id-token: write # needed to request the OIDC token
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

Terraform running as the CI/CD role can also use the deployment role through a provider `assume_role` block, while keeping its state in the CI/CD account's bucket.

### Managed policies

`managed_policy_arns` is a map of names you choose to policy ARNs. The names must be known at plan time, but the ARNs don't need to be, so you can pass a policy created in the same configuration:

```hcl
managed_policy_arns = {
  power_user = "arn:aws:iam::aws:policy/PowerUserAccess"
  app_deploy = aws_iam_policy.app_deploy.arn
}
```

Each attachment is tied to its name, so adding or removing one policy leaves the others alone. AWS-managed (`arn:aws:iam::aws:policy/...`) and customer-managed policies in any partition are accepted.

### Notes

- **Organizations required:** the workload account must belong to an AWS Organization, and so must the accounts of the trusted roles (the same one). The submodule reads the organization ID with `organizations:DescribeOrganization`, which works from member accounts, so whoever applies it in the workload account needs that permission. `PowerUserAccess` includes it.
- **Order across separate configurations:** IAM checks that a trust policy's principals exist when the policy is saved. If each account has its own configuration, apply the CI/CD role first, then this role, then add this role's ARN to `allowed_assume_role_arns` and apply the CI/CD role again.
- **Recreated CI/CD role:** if a trusted role is deleted and recreated, even with the same name, this role's trust policy stops matching it. IAM shows the old role's internal ID in place of the ARN. Apply this submodule again to fix it.
- **Session length:** sessions from role chaining are limited to one hour, whatever the role's maximum session duration is.
- **Transitive tags:** if a workflow passes `transitive-tag-keys` to `configure-aws-credentials`, every later role in the chain must set `role-skip-session-tagging: true`.
- **Naming:** `role_prefix` may contain only letters. Changing it replaces the role, so update `allowed_assume_role_arns` and your workflows too.
- **Policy limits:** at most 10 managed policies can be attached (enforced by validation). Inline policies on a role are limited to 10,240 characters in total.
- **Permissions boundary:** the policy named in `permissions_boundary_policy_name` must already exist in the workload account. The role's effective permissions are what both its policies and the boundary allow. If this role's pipelines apply Terraform that manages IAM roles (including this submodule or github-oidc-role), the boundary and its policies must allow those IAM actions.
