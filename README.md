[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit) [![pre-commit.ci status](https://results.pre-commit.ci/badge/github/brucellino/terraform-github-nomad-webhooks/main.svg)](https://results.pre-commit.ci/latest/github/brucellino/terraform-github-nomad-template/main) [![semantic-release: conventional](https://img.shields.io/badge/semantic--release-conventional-e10079?logo=semantic-release)](https://github.com/semantic-release/semantic-release)

# Github Runners on Nomad

This is a terraform module for deploying a Nomad parametrised job which can spawn Github Actions runners.
The Nomad API is exposed and protected via Cloudflare.
This module terraforms your Github repos adding webhooks to deliver payload to a Cloudflare worker.
The worker validates the payload and if the event corresponds to desired events sends a dispatch payload to Nomad to start the Github runner.
The runner job has a post-stop task to remove the runner once the Action has completed.
This results in scale to zero github runners, truly minimising cost and removing constraints on billable Github Actions time in GitHub accounts.

## Pre-commit hooks

<!-- Edit this section or delete if you make no change  -->

The [pre-commit](https://pre-commit.com) framework is used to manage pre-commit hooks for this repository.
A few well-known hooks are provided to cover correctness, security and safety in terraform.

## Examples

The `examples/` directory contains the example usage of this module.
These examples show how to use the module in your project, and are also use for testing in CI/CD.

<!--

Modify this section according to the kinds of examples you want
You may want to change the names of the examples or the kinds of
examples themselves

-->

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >1.6.0 |
| <a name="requirement_cloudflare"></a> [cloudflare](#requirement\_cloudflare) | ~> 4.43.0 |
| <a name="requirement_github"></a> [github](#requirement\_github) | ~> 6.0 |
| <a name="requirement_nomad"></a> [nomad](#requirement\_nomad) | ~> 2.3.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.5 |
| <a name="requirement_vault"></a> [vault](#requirement\_vault) | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_cloudflare"></a> [cloudflare](#provider\_cloudflare) | ~> 4.43.0 |
| <a name="provider_github"></a> [github](#provider\_github) | ~> 6.0 |
| <a name="provider_nomad"></a> [nomad](#provider\_nomad) | ~> 2.3.0 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.5 |
| <a name="provider_vault"></a> [vault](#provider\_vault) | ~> 4.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [cloudflare_access_application.nomad](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_application) | resource |
| [cloudflare_access_group.nomad](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_group) | resource |
| [cloudflare_access_policy.service](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_policy) | resource |
| [cloudflare_tunnel.nomad](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/tunnel) | resource |
| [cloudflare_tunnel_config.nomad](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/tunnel_config) | resource |
| [cloudflare_worker_domain.handle_webhooks](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/worker_domain) | resource |
| [cloudflare_worker_script.handle_webhooks](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/worker_script) | resource |
| [cloudflare_workers_kv.actions_ips](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/workers_kv) | resource |
| [cloudflare_workers_kv.github_webhook_secret](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/workers_kv) | resource |
| [cloudflare_workers_kv.nomad_job](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/workers_kv) | resource |
| [cloudflare_workers_kv.webhook_ips](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/workers_kv) | resource |
| [cloudflare_workers_kv_namespace.github](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/workers_kv_namespace) | resource |
| [github_repository_webhook.cf](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_webhook) | resource |
| [nomad_job.cloudflared](https://registry.terraform.io/providers/hashicorp/nomad/latest/docs/resources/job) | resource |
| [nomad_job.runner_dispatch](https://registry.terraform.io/providers/hashicorp/nomad/latest/docs/resources/job) | resource |
| [random_id.tunnel_secret](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [random_pet.github_secret](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/pet) | resource |
| [cloudflare_accounts.mine](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/data-sources/accounts) | data source |
| [cloudflare_zone.webhook_listener](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/data-sources/zone) | data source |
| [github_ip_ranges.theirs](https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/ip_ranges) | data source |
| [github_repositories.mine](https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/repositories) | data source |
| [vault_kv_secret_v2.github_pat](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/data-sources/kv_secret_v2) | data source |
| [vault_kv_secret_v2.service_token](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/data-sources/kv_secret_v2) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cloudflare_domain"></a> [cloudflare\_domain](#input\_cloudflare\_domain) | Name of the cloudflare Zone you own which we will deploy workers to. | `string` | n/a | yes |
| <a name="input_github_username"></a> [github\_username](#input\_github\_username) | Username of the github user you want to instrument. | `string` | `"brucellino"` | no |
| <a name="input_runner_version"></a> [runner\_version](#input\_runner\_version) | Version of the Github self-hosted runner to use | `string` | `"2.314.1"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
