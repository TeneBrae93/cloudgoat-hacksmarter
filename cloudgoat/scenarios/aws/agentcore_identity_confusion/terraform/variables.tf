

variable "cgid" {
  description = "CGID variable for unique naming"
  type        = string
  default     = "lab"
}

variable "cg_whitelist" {
  description = "User's public IP address(es)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
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
  default     = "agentcore_identity_confusion"
  type        = string
}

# Scenario Specific Variables
variable "kb_model_id" {
  description = "The ID of the foundational model used by the knowledge base."
  type        = string
  default     = "amazon.titan-embed-text-v2:0"
}
