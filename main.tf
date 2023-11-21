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
