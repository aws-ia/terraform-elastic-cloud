variable "apikey" {
  type = string
  description = "Elastic API Key"
  default     = "cWVYbm5ud0JaUTFVSEYwVFVMVFQ6eU92TEE3R2JTZC0xdnd5OFoydEFtdw=="
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