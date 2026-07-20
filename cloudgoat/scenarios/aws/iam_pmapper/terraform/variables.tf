variable "region" {
  description = "The AWS region to deploy resources into"
  default     = "us-east-1"
  type        = string
}

variable "cgid" {
  description = "CGID variable for unique naming between scenarios"
  type        = string
  default     = "lab"
}

# This resource is not needed for scenarios, but should be used on any public facing resources
variable "cg_whitelist" {
  description = "User's public IP address(es)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "stack-name" {
  description = "Name of the stack"
  default     = "CloudGoat"
  type        = string
}

variable "scenario-name" {
  description = "Name of the scenario being deployed"
  default     = "iam_pmapper"
  type        = string
}
