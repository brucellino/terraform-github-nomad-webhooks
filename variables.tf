# variables.tf
# Use this file to declare the variables that the module will use.
variable "org" {
  description = "Is the user an org?"
  default     = false
  type        = bool
}

variable "include_archived" {
  type        = bool
  default     = false
  description = "Should we include archived repos?"
}

variable "github_username" {
  description = "Username of the github user you want to instrument."
  default     = "brucellino"
  type        = string
}

variable "cloudflare_domain" {
  description = "Name of the cloudflare Zone you own which we will deploy workers to."
  type        = string
}

variable "runner_version" {
  type        = string
  default     = "2.320.0"
  description = "Version of the Github self-hosted runner to use"
}
