# Main definition
# Get a list of all of my repositories
data "github_repositories" "mine" {
  query = "user:${var.github_username}"
}

# We will use these IP ranges to tune our ZTA later
data "github_ip_ranges" "theirs" {}

# Get the cloudflare accounts from the token we've used to configure the provider
data "cloudflare_accounts" "mine" {}

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
