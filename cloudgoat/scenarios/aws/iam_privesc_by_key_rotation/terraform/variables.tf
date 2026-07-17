

variable "cgid" {
  description = "CGID variable for unique naming"
  type        = string
  default     = "lab"
}

variable "region" {
  description = "The AWS region to deploy to"
  default     = "us-east-1"
  type        = string
}

variable "stack-name" {
  description = "Name of the CloudGoat stack"
  default     = "CloudGoat"
  type        = string
}

variable "scenario-name" {
  description = "Name of the scenario"
  default     = "iam_privesc_by_key_rotation"
  type        = string
}
