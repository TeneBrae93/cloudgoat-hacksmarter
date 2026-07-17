

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
  description = "User's public IP address(es)."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "stack-name" {
  description = "Name of the stack."
  default     = "CloudGoat"
  type        = string
}

variable "scenario-name" {
  description = "Name of the scenario."
  default     = "detection-evasion"
  type        = string
}

variable "user_email" {
  description = "The email used in conjunction with sns to deliver alerts."
  type        = string
}