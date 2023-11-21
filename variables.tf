# variables.tf
# Use this file to declare the variables that the module will use.

# A dummy variable is provided to force a test validation
variable "dummy" {
  type        = string
  description = "dummy variable"
}

variable "github_username" {
  description = "Username of the github user you want to instrument."
  default     = "brucellino"
  type        = string
}
