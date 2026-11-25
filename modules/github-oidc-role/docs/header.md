# github-oidc-role

Submodule that creates an IAM role GitHub Actions workflows can assume through the GitHub OIDC identity provider, with no long-lived AWS access keys. You choose which repositories, branches, environments or events may assume it, and which managed policies it gets.

It's meant to run in the same CI/CD account as the [root module](https://github.com/flagscript/terraform-aws-flagscript-cicd), whose state access policy you can attach to this role.

## Features

- **IAM role** named `<role_prefix>GithubOidcRole`, trusted only by the account's GitHub OIDC provider (`token.actions.githubusercontent.com`).
- **Scoped trust.** The trust policy requires the `sts.amazonaws.com` audience, and matches the token's `sub` claim against the patterns in `github_repository_paths`.
- **Managed policies** from `managed_policy_arns_to_attach` are attached to the role, up to 10 (the default IAM quota per role).

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

  managed_policy_arns_to_attach = [
    "arn:aws:iam::123456789012:policy/ExampleTfStateAccessPolicy",
  ]
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

### Notes

- **Keep patterns narrow.** A pattern like `repo:example-org/*` lets every repository in the organization assume the role, and `*` on its own lets any GitHub repository do so. Prefer specific branches or environments for roles that can change infrastructure.
- **Naming:** `role_prefix` may contain only letters. Changing it replaces the role, so update `role-to-assume` in your workflows too.
- **Policy limit:** at most 10 managed policies can be attached (enforced by validation). Request an IAM quota increase if you need more, or combine permissions into fewer policies.
