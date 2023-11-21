# variables.tf
# Use this file to declare the variables that the module will use.

variable "github_username" {
  description = "Username of the github user you want to instrument."
  default     = "brucellino"
  type        = string
}
