terraform {
  backend "consul" {
    path = "terraform_github_nomad_webhooks/simple"
  }
  required_providers {
    # We need github to provide access to github
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
    # we're going to need vault to read and write secrets
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.0"
    }
    # Cloudflare will be used to create a few
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.22.0"
    }
  }
}

variable "domain" {
  description = "The domain you will be deploying to. You must already own this domain."
  default     = "brucellino.dev"
  type        = string
}

variable "secrets_mount" {
  type        = string
  description = "Name of the vault mount where the github secrets are kept."
  default     = "hashiatho.me-v2"
}

provider "vault" {}
# Use vault to get the secrets for configuring the other providers
data "vault_kv_secret_v2" "github" {
  mount = var.secrets_mount
  name  = "github"
}

data "vault_kv_secret_v2" "cloudflare" {
  mount = "cloudflare"
  name  = var.domain
}

provider "cloudflare" {
  api_token = data.vault_kv_secret_v2.cloudflare.data.github_runner_token
}

provider "github" {
  token = data.vault_kv_secret_v2.github.data.gh_token
}

provider "nomad" {

}

module "example" {
  source            = "../../"
  github_username   = "brucellino"
  cloudflare_domain = "brucellino.dev"
}
