locals {
    aws_account_id = data.aws_caller_identity.current.account_id
}

# Default VPC
resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

# SQS
resource "aws_sqs_queue" "es_queue_deadletter" {
  name = "es-queue-deadletter"
  delay_seconds = 90
  max_message_size = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
}

resource "aws_sqs_queue" "es_queue" {
  name = "es-queue"
  delay_seconds = 90
  max_message_size = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.es_queue_deadletter.arn
    maxReceiveCount     = 4
  })
  tags = {
    Name        = "SQS Queue for Elasticsearch"
    Environment = "Dev"
  }
}

# S3 Bucket for Elasticsearch snapshots
resource "aws_s3_bucket" "es_s3_snapshot" {
  bucket_prefix = var.bucket_prefix_snapshot
  acl    = "private"

  tags = {
    Name        = "Bucket for Elasticsearch snapshots"
    Environment = "Dev"
  }
}

# S3 Bucket for Elastic Agent
resource "aws_s3_bucket" "es_s3_agent" {
  bucket_prefix = var.bucket_prefix_agent
  acl    = "private"

  tags = {
    Name        = "Bucket for Elastic Agent"
    Environment = "Dev"
  }
}

# S3 Policy for bucket for snapshots
resource "aws_s3_bucket_policy" "es_s3_snapshot" {
  bucket = aws_s3_bucket.es_s3_snapshot.id

  # Terraform expression's result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "es_s3_snapshot_policy"
    Statement = [
      {
        Effect    = "Allow"
        Action    = "s3:*"
        Principal = {"AWS":"${local.aws_account_id}"}
        Resource = [
          aws_s3_bucket.es_s3_snapshot.arn,
          "${aws_s3_bucket.es_s3_snapshot.arn}/*",
        ]
      },
    ]
  })
}

# S3 Policy for bucket for Agent
resource "aws_s3_bucket_policy" "es_s3_agent" {
  bucket = aws_s3_bucket.es_s3_agent.id

  # Terraform expression's result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "es_s3_agent_policy"
    Statement = [
      {
        Effect    = "Allow"
        Action    = "s3:*"
        Principal = {"AWS":"${local.aws_account_id}"}
        Resource = [
          aws_s3_bucket.es_s3_agent.arn,
          "${aws_s3_bucket.es_s3_agent.arn}/*",
        ]
      },
    ]
  })
}

# IAM Role
resource "aws_iam_role" "es_role" {
  count = var.create_role_and_policy ? 1 : 0
  name  = "es_deploy_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "s3.amazonaws.com",
          "ec2.amazonaws.com",
          "sqs.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

#Attach IAM role
resource "aws_iam_role_policy_attachment" "es_deploy" {
  role       = aws_iam_role.es_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# AccountID
data "aws_caller_identity" "current" {}

# EC2 Instance
resource "aws_instance" "ec2_instance" {
    ami                         = coalesce(var.ami, data.aws_ami.ubuntu.id)
    instance_type               = var.instance_type
    key_name                    = var.key_name
    availability_zone           = var.availability_zone
    subnet_id                   = var.subnet_id
    vpc_security_group_ids      = var.vpc_security_group_ids
    user_data                   = var.user_data
    associate_public_ip_address = var.associate_public_ip_address

    dynamic "root_block_device" {
        for_each = var.root_block_device
        content {
        delete_on_termination = lookup(root_block_device.value, "delete_on_termination", null)
        encrypted             = lookup(root_block_device.value, "encrypted", null)
        iops                  = lookup(root_block_device.value, "iops", null)
        kms_key_id            = lookup(root_block_device.value, "kms_key_id", null)
        volume_size           = lookup(root_block_device.value, "volume_size", null)
        volume_type           = lookup(root_block_device.value, "volume_type", null)
        throughput            = lookup(root_block_device.value, "throughput", null)
        tags                  = lookup(root_block_device.value, "tags", null)
        }
    }

    tags                      = merge({ "Name" = var.ec2_name }, var.tags)
}

resource "null_resource" "bootstrap_ec2_instance" {
  provisioner "local-exec" {
    command = data.template_file.install_elastic_agent.rendered
  }
}

data "template_file" "install_elastic_agent" {
  template   = file("install_elastic_agent.sh")
  depends_on = [aws_instance.ec2_instance]
  vars = {
    # Created servers and appropriate AZs
    elastic-user     = ec_deployment.ec_minimal.elasticsearch_username
    elastic-password = ec_deployment.ec_minimal.elasticsearch_password
    es-url           = ec_deployment.ec_minimal.elasticsearch[0].https_endpoint
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}