# S3
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
    Id      = "ec_s3_policy"
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

# IAM
resource "aws_iam_role" "es_role" {
  name  = "es_deploy_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
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
