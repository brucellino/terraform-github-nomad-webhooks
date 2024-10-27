[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit) [![pre-commit.ci status](https://results.pre-commit.ci/badge/github/brucellino/terraform-github-nomad-webhooks/main.svg)](https://results.pre-commit.ci/latest/github/brucellino/terraform-github-nomad-template/main) [![semantic-release: conventional](https://img.shields.io/badge/semantic--release-conventional-e10079?logo=semantic-release)](https://github.com/semantic-release/semantic-release)

# 🚀 GitHub Runners on Nomad

Welcome to the **GitHub Runners on Nomad** Terraform module! This project allows you to deploy a parameterized Nomad job to spawn GitHub Actions runners, optimizing your CI/CD workflows.

## 🌟 Overview

This module:
- Exposes the Nomad API via Cloudflare for secure access.
- Automatically configures your GitHub repositories to add webhooks, delivering payloads to a Cloudflare worker.
- Validates incoming payloads and dispatches a job to Nomad to start a GitHub runner based on desired events.
- Implements a post-stop task to remove the runner once the GitHub Action completes, allowing for efficient scaling to zero and minimizing costs.

## 🔗 Pre-commit Hooks

This repository utilizes the [pre-commit](https://pre-commit.com) framework to manage pre-commit hooks, ensuring correctness, security, and safety in Terraform.

## 🛠️ Examples

Check out the `examples/` directory for practical usage examples of this module. These examples not only demonstrate how to implement the module in your projects but also serve as tests in CI/CD.

## 📋 Requirements

| Name                      | Version  |
|---------------------------|----------|
| [Terraform](#requirement_terraform) | >1.6.0   |
| [Cloudflare](#requirement_cloudflare) | ~> 4.44.0 |
| [GitHub](#requirement_github)         | ~> 6.0   |
| [Nomad](#requirement_nomad)           | ~> 2.4.0 |
| [Random](#requirement_random)         | ~> 3.5   |
| [Vault](#requirement_vault)           | ~> 4.0   |

## 🌐 Providers

| Name        | Version  |
|-------------|----------|
| [Cloudflare](#provider_cloudflare) | 4.44.0 |
| [GitHub](#provider_github)         | 6.3.1  |
| [Nomad](#provider_nomad)           | 2.4.0  |
| [Random](#provider_random)         | 3.6.3  |
| [Vault](#provider_vault)           | 4.4.0  |

## 📦 Modules

No modules available.

## 📜 Resources

Here are some of the key resources utilized in this module:

| Name                                                                                   | Type     |
|----------------------------------------------------------------------------------------|----------|
| [cloudflare_record.tunnel_public](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/record) | Resource |
| [cloudflare_workers_domain.handle_webhooks](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/workers_domain) | Resource |
| [nomad_job.runner_dispatch](https://registry.terraform.io/providers/hashicorp/nomad/latest/docs/resources/job) | Resource |
| [github_repository_webhook.cf](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_webhook) | Resource |

## 📥 Inputs

| Name                       | Description                                                  | Type    | Default        | Required |
|----------------------------|--------------------------------------------------------------|---------|----------------|:--------:|
| [cloudflare_domain](#input_cloudflare_domain) | Name of the Cloudflare Zone to deploy workers to.          | `string` | n/a            | yes      |
| [github_username](#input_github_username)    | GitHub username to instrument.                             | `string` | `"brucellino"` | no       |
| [include_archived](#input_include_archived)  | Should archived repos be included?                         | `bool`   | `false`       | no       |
| [org](#input_org)                            | Is the user an organization?                              | `bool`   | `false`       | no       |
| [runner_version](#input_runner_version)      | Version of the GitHub self-hosted runner to use.         | `string` | `"2.320.0"`   | no       |

## 🚫 Outputs

No outputs defined.

---

Thank you for checking out the **GitHub Runners on Nomad** module! If you have any questions or suggestions, feel free to contribute! 🌟

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >1.6.0 |
| <a name="requirement_cloudflare"></a> [cloudflare](#requirement\_cloudflare) | ~> 4.44.0 |
| <a name="requirement_github"></a> [github](#requirement\_github) | ~> 6.0 |
| <a name="requirement_nomad"></a> [nomad](#requirement\_nomad) | ~> 2.4.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.5 |
| <a name="requirement_vault"></a> [vault](#requirement\_vault) | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_cloudflare"></a> [cloudflare](#provider\_cloudflare) | ~> 4.44.0 |
| <a name="provider_github"></a> [github](#provider\_github) | ~> 6.0 |
| <a name="provider_nomad"></a> [nomad](#provider\_nomad) | ~> 2.4.0 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.5 |
| <a name="provider_vault"></a> [vault](#provider\_vault) | ~> 4.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [cloudflare_record.tunnel_public](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/record) | resource |
| [cloudflare_workers_domain.handle_webhooks](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/workers_domain) | resource |
| [cloudflare_workers_kv.actions_ips](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/workers_kv) | resource |
| [cloudflare_workers_kv.github_webhook_secret](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/workers_kv) | resource |
| [cloudflare_workers_kv.job_name](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/workers_kv) | resource |
| [cloudflare_workers_kv.webhook_ips](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/workers_kv) | resource |
| [cloudflare_workers_kv_namespace.github](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/workers_kv_namespace) | resource |
| [cloudflare_workers_script.handle_webhooks](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/workers_script) | resource |
| [cloudflare_zero_trust_tunnel_cloudflared.dispatch](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_tunnel_cloudflared) | resource |
| [cloudflare_zero_trust_tunnel_cloudflared_config.dispatch](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_tunnel_cloudflared_config) | resource |
| [github_repository_webhook.cf](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_webhook) | resource |
| [nomad_job.cloudflared](https://registry.terraform.io/providers/hashicorp/nomad/latest/docs/resources/job) | resource |
| [nomad_job.runner_dispatch](https://registry.terraform.io/providers/hashicorp/nomad/latest/docs/resources/job) | resource |
| [random_id.tunnel_secret](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [random_pet.github_secret](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/pet) | resource |
| [cloudflare_accounts.mine](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/data-sources/accounts) | data source |
| [cloudflare_zone.webhook_listener](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/data-sources/zone) | data source |
| [github_ip_ranges.theirs](https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/ip_ranges) | data source |
| [github_repositories.selected](https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/repositories) | data source |
| [vault_kv_secret_v2.service_token](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/data-sources/kv_secret_v2) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cloudflare_domain"></a> [cloudflare\_domain](#input\_cloudflare\_domain) | Name of the cloudflare Zone you own which we will deploy workers to. | `string` | n/a | yes |
| <a name="input_github_username"></a> [github\_username](#input\_github\_username) | Username of the github user you want to instrument. | `string` | `"brucellino"` | no |
| <a name="input_include_archived"></a> [include\_archived](#input\_include\_archived) | Should we include archived repos? | `bool` | `false` | no |
| <a name="input_org"></a> [org](#input\_org) | Is the user an org? | `bool` | `false` | no |
| <a name="input_runner_version"></a> [runner\_version](#input\_runner\_version) | Version of the Github self-hosted runner to use | `string` | `"2.320.0"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->