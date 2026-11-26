# github-oidc-role

Submodule that creates an IAM role GitHub Actions workflows can assume through the GitHub OIDC identity provider, with no long-lived AWS access keys. You choose which repositories, branches, environments or events may assume it, which managed policies it gets, and which roles in other accounts it may assume.

It's meant to run in the same CI/CD account as the [root module](https://github.com/flagscript/terraform-aws-flagscript-cicd), whose state access policy you can attach to this role. To deploy into workload accounts, pair it with the [deployment-role](https://github.com/flagscript/terraform-aws-flagscript-cicd/tree/main/modules/deployment-role) submodule.

## Features

- **IAM role** named `<role_prefix>GithubOidcRole`, trusted only by the account's GitHub OIDC provider (`token.actions.githubusercontent.com`).
- **Scoped trust.** The trust policy requires the `sts.amazonaws.com` audience, and matches the token's `sub` claim against the patterns in `github_repository_paths`.
- **Managed policies** from `managed_policy_arns` are attached to the role, up to 10 (the default IAM quota per role).
- **Role chaining** (optional). Roles listed in `allowed_assume_role_arns`, such as deployment roles in workload accounts, can be assumed with `sts:AssumeRole` and `sts:TagSession`.

## Prerequisites

The account must already have the GitHub OIDC identity provider for `https://token.actions.githubusercontent.com`. An account has only one per URL, so the submodule looks it up rather than creating it. If you need to create it in the same configuration, see the [github-actions](https://github.com/flagscript/terraform-aws-flagscript-cicd/tree/main/examples/github-actions) example.

## Usage

```hcl
module "github_role" {
  source  = "flagscript/flagscript-cicd/aws//modules/github-oidc-role"
  version = "~> 1.0"

  role_prefix = "Example"

  github_repository_paths = [
    "repo:example-org/infrastructure:ref:refs/heads/main",
    "repo:example-org/infrastructure:environment:production",
  ]

  managed_policy_arns = {
    tfstate = "arn:aws:iam::123456789012:policy/ExampleTfStateAccessPolicy"
  }
}
```

Then assume the role from a workflow:

```yaml
permissions:
  id-token: write # needed to request the OIDC token
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

The role ARN is also in the `github_oidc_role_arn` output.

### Repository paths

Each entry in `github_repository_paths` is matched against the token's `sub` claim with `StringLike`, so `*` and `?` wildcards work. Write the full claim, starting with `repo:`:

| Pattern | Allows |
|---------|--------|
| `repo:example-org/example-repo:ref:refs/heads/main` | Workflows running on the `main` branch |
| `repo:example-org/example-repo:ref:refs/tags/v*` | Workflows running on tags starting with `v` |
| `repo:example-org/example-repo:environment:production` | Jobs that use the `production` environment |
| `repo:example-org/example-repo:pull_request` | Workflows triggered by pull requests |
| `repo:example-org/example-repo:*` | Any workflow in the repository |

When a job uses an environment, the claim is `environment:<name>`, not the branch. Allow that pattern if your jobs use environments.

### Managed policies

`managed_policy_arns` is a map of names you choose to policy ARNs. The names must be known at plan time, but the ARNs don't need to be, so you can pass a policy created in the same configuration, such as the root module's state access policy:

```hcl
managed_policy_arns = {
  tfstate = module.cicd.terraform_state_bucket_access_policy_arn
}
```

Each attachment is tied to its name, so adding or removing one policy leaves the others alone.

### Assuming deployment roles

To let workflows deploy into other accounts, list the roles there in `allowed_assume_role_arns`. Those roles must also trust this one, which the deployment-role submodule does through `trusted_assume_role_arns`:

```hcl
module "github_role" {
  source  = "flagscript/flagscript-cicd/aws//modules/github-oidc-role"
  version = "~> 1.0"

  role_prefix             = "Example"
  github_repository_paths = ["repo:example-org/app:ref:refs/heads/main"]

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
}
```

The two modules refer to each other's outputs, but there's no dependency cycle: Terraform creates this role, then the deployment role, then the policy that lets this role assume it. A workflow then chains from this role to the deployment role with `role-chaining: true`. See the [cross-account](https://github.com/flagscript/terraform-aws-flagscript-cicd/tree/main/examples/cross-account) example.

### Notes

- **Keep patterns narrow.** A pattern like `repo:example-org/*` lets every repository in the organization assume the role, and `*` on its own lets any GitHub repository do so. Prefer specific branches or environments for roles that can change infrastructure.
- **Naming:** `role_prefix` may contain only letters. Changing it replaces the role, so update `role-to-assume` in your workflows too.
- **Assumable roles:** each entry in `allowed_assume_role_arns` must be an IAM role ARN with a 12-digit account ID (enforced by validation). A name wildcard such as `role/Deploy*` passes validation and works in IAM, but listing each role keeps the permission narrow.
- **Policy limit:** at most 10 managed policies can be attached (enforced by validation). Request an IAM quota increase if you need more, or combine permissions into fewer policies.
