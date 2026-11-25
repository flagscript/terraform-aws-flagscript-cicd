/**
 * # GitHub Actions example
 *
 * A complete CI/CD account setup: a replicated Terraform state bucket, and an IAM role that
 * GitHub Actions workflows assume through OIDC to read and write that state.
 *
 * This example:
 *
 * - creates the GitHub OIDC identity provider for `token.actions.githubusercontent.com`.
 *   An account can have only one per URL, so remove this resource if your account already
 *   has it.
 * - creates the state bucket(s) and access policy with the root module
 * - creates `ExampleGithubOidcRole` with the github-oidc-role submodule, trusted by the
 *   `main` branch and the `production` environment of one repository, and attaches the
 *   state access policy to it
 *
 * The submodule looks up the OIDC provider, so `depends_on` makes that lookup wait until
 * the provider exists.
 *
 * ```bash
 * terraform init
 * terraform apply
 * ```
 *
 * Then assume the role from a workflow, using the `github_oidc_role_arn` output:
 *
 * ```yaml
 * permissions:
 *   id-token: write
 *   contents: read
 *
 * jobs:
 *   plan:
 *     runs-on: ubuntu-latest
 *     steps:
 *       - uses: actions/checkout@v5
 *       - uses: aws-actions/configure-aws-credentials@v5
 *         with:
 *           role-to-assume: arn:aws:iam::123456789012:role/ExampleGithubOidcRole
 *           aws-region: us-east-1
 * ```
 */

provider "aws" {
  region = "us-east-1"
}

# Remove if the account already has a GitHub OIDC provider.
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

module "cicd" {
  source  = "flagscript/flagscript-cicd/aws"
  version = "~> 1.0"

  primary_region      = "us-east-1"
  secondary_region    = "us-west-2"
  state_bucket_prefix = "example"

  tags = {
    Environment = "example"
  }
}

module "github_role" {
  source  = "flagscript/flagscript-cicd/aws//modules/github-oidc-role"
  version = "~> 1.0"

  depends_on = [aws_iam_openid_connect_provider.github]

  role_prefix = "Example"

  github_repository_paths = [
    "repo:example-org/infrastructure:ref:refs/heads/main",
    "repo:example-org/infrastructure:environment:production",
  ]

  managed_policy_arns_to_attach = [
    module.cicd.terraform_state_bucket_access_policy_arn,
  ]

  tags = {
    Environment = "example"
  }
}
