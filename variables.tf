variable "apikey" {
  type = string
  description = "Elastic API Key"
}

variable "alias" {
  type = string
  description = ""
}

variable "apm_secret_token" {
  type = string
  description = ""
}

variable "deployment_template_id" {
  type = string
  description = ""
  default = "aws-io-optimized-v2"
}

variable "elasticsearch_password" {
  type = string
  description = ""
}

variable "elasticsearch_username" {
  type = string
  description = ""
}

variable "id" {
  type = string
  description = ""
  default     = "7.15.1"
}

variable "name" {
  type = string
  description = "Deployment Name"
}

variable "region" {
  type = string
  description = "AWS Region"
  default = "us-east-1"
}

variable "autoscale" {
  type = string
  default = "true"
}

variable "zone_count" {
  type = number
  default = 1
}

variable "sourceip" {
  default = "0.0.0.0/0"
}

variable "create_role_and_policy" {
  description = "Create a new IAM role and policy if true"
  type        = bool
  default     = true
}