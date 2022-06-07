locals {
  es_credentials = sensitive(jsondecode(aws_secretsmanager_secret_version.es_credentials.secret_string))
  aws_access_key = sensitive(var.s3_client_access_key)
  aws_secret_key = sensitive(var.s3_client_secret_key)
  ess_api_key    = sensitive(var.apikey)
}

# AWS Secrets Manager – Stores auto-generated elasticsearch credentials during the deployment
resource "aws_secretsmanager_secret" "es_secrets" {
  name_prefix = "es_secrets"
  kms_key_id  = var.kms_key_id
  depends_on  = [ec_deployment.ec_minimal]
}

resource "aws_secretsmanager_secret_version" "es_credentials" {
  secret_id     = aws_secretsmanager_secret.es_secrets.id
  secret_string = <<EOF
  {
    "es_url" : "${ec_deployment.ec_minimal.elasticsearch[0].https_endpoint}",
    "elasticsearch_username": "${ec_deployment.ec_minimal.elasticsearch_username}",
    "elasticsearch_password": "${ec_deployment.ec_minimal.elasticsearch_password}"
  }
EOF
  depends_on    = [aws_secretsmanager_secret.es_secrets]
}

resource "aws_kms_key" "akk" {
  description         = "KMS key"
  enable_key_rotation = "true"
}

resource "aws_kms_alias" "aka" {
  name          = "alias/akk"
  target_key_id = aws_kms_key.akk.key_id
}