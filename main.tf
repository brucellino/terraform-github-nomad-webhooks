# Main definition
# Get a list of all of my repositories

locals {
  owner_type = var.org ? "org" : "user"
}
data "github_repositories" "selected" {
  query = "${local.owner_type}:${var.github_username} archived:${var.include_archived} topic:hah-runner fork:false"
}

# We will use these IP ranges to tune our ZTA later
data "github_ip_ranges" "theirs" {}

# Get the cloudflare accounts from the token we've used to configure the provider
data "cloudflare_account" "mine" {
  filter = {
    name = "brucellino"
  }
}

# The webhook listener zone is where we will register a dns name for the worker which will receive the github webhooks
data "cloudflare_zone" "webhook_listener" {
  filter = {
    account_id = data.cloudflare_account.mine.id
    name       = var.cloudflare_domain
  }
}

# This may be obsolete.
data "vault_kv_secret_v2" "service_token" {
  mount = "cloudflare"
  name  = var.cloudflare_domain
}

# A cloudflare kv namespace will store the shared secret which the
# Github webhook uses to sign it's payload.
# resource "cloudflare_workers_kv_namespace" "github" {
#   account_id = data.cloudflare_account.mine.id
#   title      = "${var.github_username}_github_runner"
# }

# # We keep the webhook ips in it in order to ensure that we can later restrict
# # access to the receiver only from these IPs
# resource "cloudflare_workers_kv" "webhook_ips" {
#   account_id   = data.cloudflare_account.mine.id
#   namespace_id = cloudflare_workers_kv_namespace.github.id
#   key_name          = "github_webhook_cidrs"
#   value        = jsonencode(data.github_ip_ranges.theirs.hooks_ipv4)
# }

# # Actions IPs are the urls which actions send data from.
# # These are stored in the same kv namespace in order to configure the
# # tunnel later.
# resource "cloudflare_workers_kv" "actions_ips" {
#   account_id   = data.cloudflare_account.mine.id
#   namespace_id = cloudflare_workers_kv_namespace.github.id
#   key_name          = "github_actions_cidrs"
#   value        = jsonencode(data.github_ip_ranges.theirs.actions_ipv4)
# }

# # Create a secret for the webhook
# resource "random_pet" "github_secret" {
#   length    = 3
#   prefix    = "hashi"
#   separator = "_"
#   keepers = {
#     "repo" = data.github_repositories.selected.id
#   }
# }
# # Store it in the KV store for the script to pick up later.
# resource "cloudflare_workers_kv" "github_webhook_secret" {
#   account_id   = data.cloudflare_account.mine.id
#   namespace_id = cloudflare_workers_kv_namespace.github.id
#   key_name          = "github_webhook_secret"
#   value        = random_pet.github_secret.id
# }

# # First the tunnel.
# resource "cloudflare_zero_trust_tunnel_cloudflared" "dispatch" {
#   name       = "nomad-${var.github_username}"
#   account_id = data.cloudflare_account.mine.id
#   tunnel_secret     = random_id.tunnel_secret.b64_std
#   config_src = "cloudflare"
# }

# moved {
#   from = cloudflare_record.tunnel_public
#     to = cloudflare_dns_record.tunnel_public
# }

# resource "cloudflare_dns_record" "tunnel_public" {
#   zone_id = data.cloudflare_zone.webhook_listener.zone_id
#   name    = "dispatch-workload-${var.github_username}"
#   content = "${cloudflare_zero_trust_tunnel_cloudflared.dispatch.id}.cfargotunnel.com"
#   # data {
#   #   target = "${cloudflare_zero_trust_tunnel_cloudflared.dispatch.id}.cfargotunnel.com"
#   # }
#   proxied = true
#   comment = "Created by Terraform"
#   type    = "CNAME"
#   ttl     = 1
# }


# # Cloudflared zero trust tunnel configuration.
# # Used to configure the actual tunnel.
# resource "cloudflare_zero_trust_tunnel_cloudflared_config" "dispatch" {
#   account_id = data.cloudflare_account.mine.id
#   tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.dispatch.id
#   config = {
#     ingress = [{
#       hostname = "dispatch-workload-${var.github_username}.${var.cloudflare_domain}"
#       path     = "/"
#       service  = "http://nomad.service.consul:4646"
#       origin_request = {
#         bastion_mode             = false
#         disable_chunked_encoding = true
#         http2_origin             = false
#         keep_alive_connections   = 0
#         no_happy_eyeballs        = true
#         no_tls_verify            = true
#         proxy_port               = 0
#       }
#     }]
#   }
# }

# # The workers script for the given account.
# resource "cloudflare_workers_script" "handle_webhooks" {
#   account_id = data.cloudflare_account.mine.id
#   script_name       = "github_handle_incoming_webhooks_${var.github_username}"
#   content = templatefile("${path.module}/scripts/handle_incoming_webhooks.js.tmpl", {
#     # tunnel_url = cloudflare_zero_trust_tunnel_cloudflared.dispatch.,
#     domain     = var.cloudflare_domain,
#     owner      = var.github_username
#   })
#   bindings = [
#     {
#       name = "WORKERS",
#       type = "kv_namespace"
#       namespace = cloudflare_workers_kv_namespace.github.id
#     },
#     {
#       name = "NOMAD_ACL_TOKEN",
#       type = "plain_text"
#       text = data.vault_kv_secret_v2.service_token.data.nomad_acl_token
#     }
#   ]
#   observability = {
#     enabled = true
#     head_sampling_rate = 1
#   }
#   placement = {
#     mode = "smart"
#   }
# }

# moved {
#   from = cloudflare_workers_domain.handle_webhooks
#     to = cloudflare_workers_custom_domain.handle_webhooks
# }

# # Create the domain for the webhook handler.
# # POST from github will go here thanks to the route below
# resource "cloudflare_workers_custom_domain" "handle_webhooks" {
#   account_id = data.cloudflare_account.mine.id
#   environment = "production"
#   hostname   = "receive-webhook-${var.github_username}.${var.cloudflare_domain}"
#   service    = cloudflare_workers_script.handle_webhooks.id
#   zone_id    = data.cloudflare_zone.webhook_listener.zone_id
# }

# resource "github_repository_webhook" "cf" {
#   depends_on = [
#     cloudflare_zero_trust_tunnel_cloudflared.dispatch,
#     nomad_job.cloudflared
#   ]
#   for_each   = toset(data.github_repositories.selected.names)
#   repository = each.value
#   configuration {
#     url          = "https://${cloudflare_workers_custom_domain.handle_webhooks.hostname}"
#     content_type = "json"
#     insecure_ssl = false
#     secret       = random_pet.github_secret.id
#   }

#   active = true
#   events = ["workflow_run", "pull_request", "workflow_job"]
# }

# # Generate a >32byte base64 string to use at the tunnel password
# resource "random_id" "tunnel_secret" {
#   keepers = {
#     service = var.github_username
#   }
#   byte_length = 32
# }

# # Create the job that runs the tunnel in nomad
# resource "nomad_job" "cloudflared" {
#   jobspec = templatefile("${path.module}/jobspec/tunnel-job.hcl", {
#     token       = cloudflare_zero_trust_tunnel_cloudflared.dispatch.tunnel_secret,
#     github_user = var.github_username
#   })
# }

# # Add dispatch batch job for workload
# resource "nomad_job" "runner_dispatch" {
#   jobspec = templatefile("${path.module}/jobspec/runner-dispatch.hcl.tmpl", {
#     job_name       = "github-runner-on-demand-${var.github_username}",
#     runner_version = var.runner_version,
#     # runner_label   = "hah,self-hosted,hashi-at-home",
#     # check_token = data.vault_kv_secret_v2.github_pat.data.token
#   })
# }

# resource "cloudflare_workers_kv" "job_name" {
#   account_id   = data.cloudflare_account.mine.id
#   namespace_id = cloudflare_workers_kv_namespace.github.id
#   key_name          = "nomad_job"
#   value        = nomad_job.runner_dispatch.id
# }
