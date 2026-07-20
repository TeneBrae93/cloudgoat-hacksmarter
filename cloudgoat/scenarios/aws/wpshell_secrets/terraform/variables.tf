variable "region" {
  description = "The AWS region to deploy resources to."
  default     = "us-east-1"
  type        = string
}

variable "cgid" {
  description = "CGID variable for unique naming."
  type        = string
  default     = "lab"
}

variable "cg_whitelist" {
  description = "User's public IP address"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ssh_public_key" {
  description = "Where to store the public key"
  default     = "cloudgoat.pub"
  type        = string
}

variable "ssh_private_key" {
  description = "Where to store the private key"
  default     = "cloudgoat"
  type        = string
}

variable "stack-name" {
  description = "Name of the stack."
  default     = "CloudGoat"
  type        = string
}

variable "scenario-name" {
  description = "Name of the scenario."
  default     = "wpshell_secrets"
  type        = string
}
