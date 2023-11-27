# Main definition
# Get a list of all of my repositories
data "github_repositories" "mine" {
  query = "user:${var.github_username} archived:false"
}

# We will use these IP ranges to tune our ZTA later
data "github_ip_ranges" "theirs" {}

# Get the cloudflare accounts from the token we've used to configure the provider
data "cloudflare_accounts" "mine" {}

data "cloudflare_zone" "webhook_listener" {
  name = var.cloudflare_domain
}

data "vault_kv_secret_v2" "service_token" {
  mount = "cloudflare"
  name  = var.cloudflare_domain
}

resource "cloudflare_workers_kv_namespace" "github" {
  account_id = data.cloudflare_accounts.mine.accounts[0].id
  title      = "${var.github_username}_github_runner"
}

resource "cloudflare_workers_kv" "webhook_ips" {
  account_id   = data.cloudflare_accounts.mine.accounts[0].id
  namespace_id = cloudflare_workers_kv_namespace.github.id
  key          = "github_webhook_cidrs"
  value        = jsonencode(data.github_ip_ranges.theirs.hooks_ipv4)
}

resource "cloudflare_workers_kv" "actions_ips" {
  account_id   = data.cloudflare_accounts.mine.accounts[0].id
  namespace_id = cloudflare_workers_kv_namespace.github.id
  key          = "github_actions_cidrs"
  value        = jsonencode(data.github_ip_ranges.theirs.actions_ipv4)
}


resource "cloudflare_worker_script" "handle_webhooks" {
  account_id = data.cloudflare_accounts.mine.accounts[0].id
  name       = "github_handle_incoming_webhooks_${var.github_username}"
  content    = file("${path.module}/scripts/handle_incoming_webhooks.js")
  kv_namespace_binding {
    name         = "KV_NAMESPACE"
    namespace_id = cloudflare_workers_kv_namespace.github.id
  }

  secret_text_binding {
    name = "CF_ACCESS_CLIENT_ID"
    text = data.vault_kv_secret_v2.service_token.data.cf_access_client_id
  }

  secret_text_binding {
    name = "CF_ACCESS_CLIENT_SECRET"
    text = data.vault_kv_secret_v2.service_token.data.cf_access_client_secret
  }
  module = true
}

resource "cloudflare_worker_domain" "handle_webhooks" {
  account_id = data.cloudflare_accounts.mine.accounts[0].id
  hostname   = "github_webhook.${var.cloudflare_domain}"
  service    = cloudflare_worker_script.handle_webhooks.name
  zone_id    = data.cloudflare_zone.webhook_listener.zone_id
}

resource "github_repository_webhook" "cf" {
  for_each   = toset(data.github_repositories.mine.names)
  repository = each.value
  configuration {
    url          = "https://${cloudflare_worker_domain.handle_webhooks.hostname}"
    content_type = "json"
    insecure_ssl = false
  }

  active = true
  events = ["workflow_run", "pull_request"]
}


# Only /16 or /24 can be used for these
# see https://community.cloudflare.com/t/ip-access-rule-api-error-cidr-range-firewallaccessrules-api-validation-error-invalid-ip-provided/399939/4?u=brucellino
# resource "cloudflare_access_rule" "github_webhooks" {
#   for_each   = toset(data.github_ip_ranges.theirs.hooks)
#   account_id = data.cloudflare_accounts.mine.accounts[0].id
#   notes      = "Allow incoming from Github webhooks"
#   mode       = "whitelist"
#   configuration {
#     target = "ip_range"
#     value  = each.value
#   }
# }

# resource "cloudflare_access_application" "nomad" {
#   account_id = data.cloudflare_accounts.mine.accounts[0].id
#   name       = "Nomad Github Runners"

# }


# Create the tunnel


# Create the job that runs the tunnel in nomad
resource "cloudflare_access_application" "nomad" {
  account_id          = data.cloudflare_accounts.mine.accounts[0].id
  name                = "nomad"
  custom_deny_url     = "https://hashiatho.me"
  type                = "self_hosted"
  domain              = "nomad.brucellino.dev"
  self_hosted_domains = ["nomad.hashiatho.me", "nomad.brucellino.dev"]
}

# Create access group for using the application
resource "cloudflare_access_group" "nomad" {
  account_id = data.cloudflare_accounts.mine.accounts[0].id
  name       = "github-webhook-worker"
  include {
    any_valid_service_token = true
  }

  require {
    any_valid_service_token = true
  }
}

# Create policy for application with the access group added
resource "cloudflare_access_policy" "service" {
  name           = "ServiceWorker"
  application_id = cloudflare_access_application.nomad.id
  decision       = "allow"
  precedence     = "10"
  account_id     = data.cloudflare_accounts.mine.accounts[0].id
  require {
    any_valid_service_token = true
  }
  include {
    service_token = ["fcbd819b-771c-4e0b-a22e-d38e8361d2e8"]
    group         = [cloudflare_access_group.nomad.id]
  }
}

# Generate a >32byte base64 string to use at the tunnel password
resource "random_id" "tunnel_secret" {
  keepers = {
    service = cloudflare_access_application.nomad.id
  }
  byte_length = 32
}

# Create tunnel connected to the application route
resource "cloudflare_tunnel" "nomad" {
  name       = "nomad"
  account_id = data.cloudflare_accounts.mine.accounts[0].id
  secret     = random_id.tunnel_secret.b64_std
  config_src = "cloudflare"
}

# Add the Nomad job for cloudflare
resource "nomad_job" "cloudflared" {
  jobspec = templatefile("${path.module}/jobspec/tunnel-job.hcl", {
    token = cloudflare_tunnel.nomad.tunnel_token
  })
}
