# Main definition
data "github_repositories" "mine" {
  query = "user:${var.github_username}"
}

data "github_ip_ranges" "theirs" {}
