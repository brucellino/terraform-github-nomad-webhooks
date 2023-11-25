# Use this file to declare the terraform configuration
# Add things like:
# - required version
# - required providers
# Do not add things like:
# - provider configuration
# - backend configuration
# These will be declared in the terraform document which consumes the module.

terraform {
  required_version = ">1.6.0"
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
      version = "~> 4.19.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}
