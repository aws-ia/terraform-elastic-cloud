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

# EC2
variable "ami" {
  description = "AMI ID for the instance"
  type        = string
  default     = ""
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