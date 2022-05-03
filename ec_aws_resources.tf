locals {
    aws_account_id = sensitive(data.aws_caller_identity.current.account_id)
}

# SQS
resource "aws_sqs_queue" "es_queue_deadletter" {
  name = "es_queue_deadletter"
  sqs_managed_sse_enabled = true
  delay_seconds = 90
  max_message_size = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
}

resource "aws_sqs_queue" "es_queue" {
  name = "es_queue"
  sqs_managed_sse_enabled = true
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
    Environment = "Development"
  }
}


# S3 Bucket for Elasticsearch repository
resource "aws_s3_bucket" "es_s3_repo" {
  bucket_prefix = var.repo_s3_bucket_prefix
  force_destroy = true

  tags = {
    Name        = "Bucket for Elasticsearch snapshots"
    Environment = "Development"
  }
}

# S3 Policy for bucket for Elasticsearch snapshot
resource "aws_s3_bucket_policy" "es_s3_repo" {
  bucket = aws_s3_bucket.es_s3_repo.id

  # Terraform expression's result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "es_s3_repo_policy"
    Statement = [
      {
        Effect    = "Allow"
        Action    = "s3:*"
        Principal = {"AWS":"${local.aws_account_id}"}
        Resource = [
          aws_s3_bucket.es_s3_repo.arn,
          "${aws_s3_bucket.es_s3_repo.arn}/*",
        ]
      },
    ]
  })
}

# S3 public access block for Elasticsearch snapshot
resource "aws_s3_bucket_public_access_block" "es_s3_repo" {
  bucket = aws_s3_bucket.es_s3_repo.id
  block_public_acls = true
  block_public_policy = true
  restrict_public_buckets = true
  ignore_public_acls = true
}

# S3 Bucket for Elastic Agent
resource "aws_s3_bucket" "es_s3_agent" {
  bucket_prefix = var.agent_s3_bucket_prefix
  force_destroy = true

  tags = {
    Name        = "Bucket for Elastic Agent"
    Environment = "Development"
  }
}

# S3 Policy for bucket for Elastic Agent
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

# S3 public access block for Elastic Agent
resource "aws_s3_bucket_public_access_block" "es_s3_agent" {
  bucket = aws_s3_bucket.es_s3_agent.id
  block_public_acls = true
  block_public_policy = true
  restrict_public_buckets = true
  ignore_public_acls = true
}

# S3 upload esf_sar_config file to the bucket
resource "aws_s3_object" "esf_sar_config" {
  bucket  = aws_s3_bucket.es_s3_repo.id
  key     = "config/sar_config.yaml"
  content = data.template_file.init_sar_config.rendered
  etag   = md5(data.template_file.init_sar_config.rendered)
  depends_on = [aws_secretsmanager_secret.es_secrets]
}

data "template_file" "init_sar_config" {
  template = file("sar_config.yaml")
  vars = {
    sm-es-url  = "${aws_secretsmanager_secret.es_secrets.arn}:es_url"
    sm-ec-user = "${aws_secretsmanager_secret.es_secrets.arn}:elasticsearch_username"
    sm-ec-pwd  = "${aws_secretsmanager_secret.es_secrets.arn}:elasticsearch_password"
  }
}

# IAM Role
resource "aws_iam_role" "es_role" {
  name_prefix  = "es_deploy_role"
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
          "sqs.amazonaws.com",
          "lambda.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Attach IAM role
resource "aws_iam_role_policy_attachment" "es_deploy" {
  depends_on = [aws_iam_role.es_role]
  role       = aws_iam_role.es_role.name
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
    user_data                   = coalesce(var.user_data, data.template_file.install_elastic_agent.rendered)
    associate_public_ip_address = var.associate_public_ip_address

    metadata_options {
        http_endpoint               = "enabled"
        http_put_response_hop_limit = 1
        http_tokens                 = "required"
    }

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

data "template_file" "install_elastic_agent" {
  template   = file("install_elastic_agent.sh")
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

# Elastic serverless forwarder (ESF) from AWS Serverless Application Repository (SAR) for log ingestion
data "aws_serverlessapplicationrepository_application" "esf_app" {
  application_id = "arn:aws:serverlessrepo:eu-central-1:267093732750:applications/elastic-serverless-forwarder"
}

resource "aws_serverlessapplicationrepository_cloudformation_stack" "esf_cfn_stack" {
  name             = "elastic-serverless-forwarder"
  application_id   = data.aws_serverlessapplicationrepository_application.esf_app.application_id
  semantic_version = data.aws_serverlessapplicationrepository_application.esf_app.semantic_version
  capabilities     = data.aws_serverlessapplicationrepository_application.esf_app.required_capabilities
  parameters = {
    ElasticServerlessForwarderS3ConfigFile = "${aws_s3_bucket.es_s3_repo.bucket_regional_domain_name}/config/sar_config.yaml"
  }
}