terraform {
  required_version = "~> 1.9"
  backend "consul" {
    path = "terraform_github_nomad_webhooks/simple"
  }
  required_providers {
    # We need github to provide access to github
    github = {
      source  = "integrations/github"
      version = "~> 6"
    }
    # we're going to need vault to read and write secrets
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4"
    }
    # Cloudflare will be used to create a few
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4"
    }
    nomad = {
      source  = "hashicorp/nomad"
      version = "~> 2"
    }
  }
}

provider "vault" {}
# Use vault to get the secrets for configuring the other providers
data "vault_kv_secret_v2" "github" {
  mount = "hashiatho.me-v2"
  name  = "github"
}

data "vault_kv_secret_v2" "cloudflare" {
  mount = "hashiatho.me-v2"
  name  = "cloudflare"
}


provider "cloudflare" {
  api_token = data.vault_kv_secret_v2.cloudflare.data.api_token
}

provider "github" {
  token = data.vault_kv_secret_v2.github.data.gh_token
  alias = "personal"
}

provider "github" {
  token = data.vault_kv_secret_v2.github.data.gh_token
  owner = "hashi-at-home"
  alias = "hah"
}

provider "nomad" {}

module "mine" {
  providers = {
    github = github.personal
  }
  source            = "../../"
  org               = false
  include_archived  = false
  github_username   = "brucellino"
  cloudflare_domain = "brucellino.dev"
}

module "hah" {
  providers = {
    github = github.hah
  }
  source            = "../../"
  org               = true
  include_archived  = false
  github_username   = "hashi-at-home"
  cloudflare_domain = "brucellino.dev"
}
