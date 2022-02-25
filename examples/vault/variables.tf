variable "apikey" {
  type = string
  description = "Elasticsearch Service API Key"
  sensitive = true
}

variable "deployment_version" {
  type = string
  description = "Elastic Cloud Deployment Version"
  default = "7.17.0"
}

variable "deployment_template_id" {
  type = string
  default = "aws-io-optimized-v2"
}

variable "name" {
  type = string
  description = "Deployment Name"
}

variable "region" {
  type = string
  description = "AWS Region"
  default = "us-west-2"
}

variable "autoscale" {
  type = string
  default = "false"
}

variable "zone_count" {
  type = number
  default = 1
}

variable "sourceip" {
  default = "0.0.0.0/0"
}

variable "existing_s3_repo_bucket_name" {
  type = string
  description = "Existing S3 bucket name for repository"
  default = ""
}

variable "s3_client_access_key" {
  type = string
  description = "Access Key ID for the S3 repository"
  default = null
  sensitive = true
}

variable "s3_client_secret_key" {
  type = string
  description = "Secret Access Key for the S3 repository"
  default = null
  sensitive = true
}

variable "local_elasticsearch_url" {
  type = string
  description = "Migrates self-hosted Elasticsearch data if its URL is provided – e.g., http://127.0.0.1:9200"
  default = ""
}

variable "local_elasticsearch_repo_name" {
  type        = string
  description = "Creates an S3 repository with the specified name for the local cluster"
  default     = "es-index-backups"
}

variable "repo_s3_bucket_prefix" {
  type        = string
  description = "Creates a unique bucket name beginning with the specified prefix"
  default     = "es-s3-repo"
}

variable "agent_s3_bucket_prefix" {
  type        = string
  description = "Creates a unique bucket name beginning with the specified prefix"
  default     = "es-s3-agent"
}

# EC2
variable "ami" {
  type        = string
  description = "AMI ID for the instance"
  default     = null
}

variable "key_name" {
  type        = string
  description = "Key name of the EC2 Key Pair to use for the instance."
  default     = null
}

variable "instance_type" {
  type        = string
  description = "The type of instance to start"
  default     = "t3.micro"
}

variable "availability_zone" {
  type        = string
  description = "Availability Zone into which the instance is deployed"
  default     = null
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID"
  default     = null
}

variable "vpc_security_group_ids" {
  type        = list(string)
  description = "A list of security group IDs with which to associate the instance"
  default     = null
}

variable "user_data" {
  type        = string
  description = "The user data to provide when launching the instance."
  default     = null
}

variable "associate_public_ip_address" {
  type        = bool
  description = "Whether to associate a public IP address with an instance in a VPC"
  default     = null
}

variable "root_block_device" {
  type        = list(any)
  description = "Details about the root block device of the instance."
  default     = []
}

variable "ec2_name" {
  type = string
  description = "EC2 Name"
  default = "single-instance"
}

variable "tags" {
  type        = map(string)
  description = "tags, which could be used for additional tags"
  default     = {}
}

# Vault
variable "vault_address" {
  description = "URL of the Vault server"
  default     = null
}

variable "vault_aws_path" {
  description = "Path to where AWS Secret Access keys exist within Vault"
  type        = string
  default     = null
}

variable "vault_ess_path" {
  description = "Path to where Elasticsearch Service (ESS) API key exist within Vault"
  type        = string
  default     = null
}