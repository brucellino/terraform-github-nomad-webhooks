terraform {
  required_version = ">1.6.0"
  required_providers {
    # We need github to provide access to github
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
    # we're going to need vault to read and write secrets
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.0"
    }
    # Cloudflare will be used to create a few
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.5.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    nomad = {
      source  = "hashicorp/nomad"
      version = "~> 2.5.0"
    }
  }
}
