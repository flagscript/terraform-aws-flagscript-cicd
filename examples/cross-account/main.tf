/**
 * # Cross-account example
 *
 * GitHub Actions deploying into a workload account from a central CI/CD account.
 *
 * In the CI/CD account (`111111111111`), this example:
 *
 * - creates the Terraform state bucket and its access policy with the root module
 * - creates `ExampleGithubOidcRole` with the github-oidc-role submodule, trusted by the
 *   `main` branch of one repository, with the state access policy attached and permission
 *   to assume the deployment role
 *
 * In the workload account (`222222222222`), it:
 *
 * - creates `ExampleDeploymentRole` with the deployment-role submodule, trusted by the
 *   GitHub Actions role, with the AWS-managed `PowerUserAccess` policy and an inline policy
 *   created in this configuration
 *
 * The two role modules refer to each other's outputs, and Terraform orders the work
 * itself: the GitHub Actions role first, then the deployment role, then the policy that
 * lets the GitHub Actions role assume it.
 *
 * The CI/CD account must already have the GitHub OIDC identity provider. The `workload`
 * provider reaches the workload account by assuming `OrganizationAccountAccessRole`, which
 * AWS Organizations creates in accounts it creates. Use any role you can assume there.
 *
 * ```bash
 * terraform init
 * terraform apply
 * ```
 *
 * Then, in a workflow, assume the GitHub Actions role and chain to the deployment role:
 *
 * ```yaml
 * permissions:
 *   id-token: write
 *   contents: read
 *
 * jobs:
 *   deploy:
 *     runs-on: ubuntu-latest
 *     steps:
 *       - uses: actions/checkout@v5
 *       - uses: aws-actions/configure-aws-credentials@v5
 *         with:
 *           role-to-assume: arn:aws:iam::111111111111:role/ExampleGithubOidcRole
 *           aws-region: us-east-1
 *       - uses: aws-actions/configure-aws-credentials@v5
 *         with:
 *           role-to-assume: arn:aws:iam::222222222222:role/ExampleDeploymentRole
 *           aws-region: us-east-1
 *           role-chaining: true
 * ```
 */

# CI/CD account
provider "aws" {
  alias  = "cicd"
  region = "us-east-1"
}

# Workload account
provider "aws" {
  alias  = "workload"
  region = "us-east-1"

  assume_role {
    role_arn = "arn:aws:iam::222222222222:role/OrganizationAccountAccessRole"
  }
}

module "cicd" {
  source  = "flagscript/flagscript-cicd/aws"
  version = "~> 1.0"

  providers = {
    aws = aws.cicd
  }

  primary_region      = "us-east-1"
  state_bucket_prefix = "example"

  tags = {
    Environment = "example"
  }
}

module "github_role" {
  source  = "flagscript/flagscript-cicd/aws//modules/github-oidc-role"
  version = "~> 1.0"

  providers = {
    aws = aws.cicd
  }

  role_prefix = "Example"

  github_repository_paths = [
    "repo:example-org/app:ref:refs/heads/main",
  ]

  managed_policy_arns = {
    tfstate = module.cicd.terraform_state_bucket_access_policy_arn
  }

  allowed_assume_role_arns = [
    module.deployment_role.deployment_role_arn,
  ]

  tags = {
    Environment = "example"
  }
}

# Permissions specific to this workload, kept inline on the deployment role.
data "aws_iam_policy_document" "app_deploy" {
  provider = aws.workload

  statement {
    sid       = "PassAppRoles"
    actions   = ["iam:PassRole"]
    resources = ["arn:aws:iam::222222222222:role/app-*"]
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
    module.github_role.github_oidc_role_arn,
  ]

  managed_policy_arns = {
    power_user = "arn:aws:iam::aws:policy/PowerUserAccess"
  }

  inline_policy_json_document = data.aws_iam_policy_document.app_deploy.json

  tags = {
    Environment = "example"
  }
}
