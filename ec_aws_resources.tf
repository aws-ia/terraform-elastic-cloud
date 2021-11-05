# S3 Bucket
resource "aws_s3_bucket" "es_s3" {
  bucket = "ec_bucket"
  acl    = "private"

  tags = {
    Name        = "Elastic bucket"
    Environment = "Dev"
  }
}

# S3 Policy
resource "aws_s3_bucket_policy" "es_s3" {
  bucket = aws_s3_bucket.es_s3.id

  # Terraform expression's result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "es_s3_policy"
    Statement = [
      {
        Sid       = "IPAllow"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.es_s3.arn,
          "${aws_s3_bucket.es_s3.arn}/*",
        ]
        Condition = {
          NotIpAddress = {
            "aws:SourceIp" = "8.8.8.8/32"
          }
        }
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
          "ec2.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "es_deploy" {
  role       = aws_iam_role.es_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# EC2
data "aws_caller_identity" "current" {}

resource "aws_instance" "ec2_instance" {
    ami                         = var.ami
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

    tags                        = merge({ "Name" = var.ec2_name }, var.tags)
}