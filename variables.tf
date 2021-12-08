variable "apikey" {
  type = string
  description = "Elastic API Key"
}

variable "deployment_template_id" {
  type = string
  description = ""
  default = "aws-io-optimized-v2"
}

variable "elasticsearch_username" {
  type = string
}

variable "elasticsearch_password" {
  type = string
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
  default = "false"
}

variable "zone_count" {
  type = number
  default = 1
}

variable "sourceip" {
  default = "0.0.0.0/0"
}

variable "existing_snapshot_s3_bucket_name" {
  type = string
  description = "Existing S3 bucket name for snapshots"
}

variable "snapshot_s3_access_key_id" {
  type = string
  description = "Access Key ID for the S3 for snapshots"
}

variable "snapshot_s3_secret_access_key" {
  type = string
  description = "Secret Access Key for the S3 for snapshots"
}

variable "local_elasticsearch_url" {
  description = "Create a local snapshot repo, provide the local elasticsearch url – e.g., http://127.0.0.1:9200"
}

variable "snapshot_s3_bucket_prefix" {
  description = "Creates a unique bucket name beginning with the specified prefix"
  type        = string
  default     = "es-s3-snapshot"
}

variable "agent_s3_bucket_prefix" {
  description = "Creates a unique bucket name beginning with the specified prefix"
  type        = string
  default     = "es-s3-agent"
}

variable "snapshot_local_repo_name" {
  description = "Creates a snapshot repository with the specified name"
  type        = string
  default     = "es-index-backups"
}

# EC2
variable "ami" {
  description = "AMI ID for the instance"
  type        = string
  default     = null
}

variable "key_name" {
  description = "Key name of the EC2 Key Pair to use for the instance."
  type        = string
  default     = null
}

variable "instance_type" {
  description = "The type of instance to start"
  type        = string
  default     = "t3.micro"
}

variable "availability_zone" {
  description = "Availability Zone into which the instance is deployed"
  type        = string
  default     = null
}

variable "subnet_id" {
  description = "Subnet ID"
  type        = string
  default     = null
}

variable "vpc_security_group_ids" {
  description = "A list of security group IDs with which to associate the instance"
  type        = list(string)
  default     = null
}

variable "user_data" {
  description = "The user data to provide when launching the instance."
  type        = string
  default     = null
}

variable "associate_public_ip_address" {
  description = "Whether to associate a public IP address with an instance in a VPC"
  type        = bool
  default     = null
}

variable "root_block_device" {
  description = "Details about the root block device of the instance."
  type        = list(any)
  default     = []
}

variable "ec2_name" {
  type = string
  description = "EC2 Name"
  default = "single-instance"
}

variable "tags" {
  description = "tags, which could be used for additional tags"
  type        = map(string)
  default     = {}
}