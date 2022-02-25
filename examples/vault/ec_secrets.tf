locals {
  es_credentials = sensitive(jsondecode(aws_secretsmanager_secret_version.es_credentials.secret_string))
  aws_access_key = sensitive("${data.vault_generic_secret.aws_creds.data["s3_client_access_key"]}")
  aws_secret_key = sensitive("${data.vault_generic_secret.aws_creds.data["s3_client_secret_key"]}")
  ess_api_key    = sensitive("${data.vault_generic_secret.ess_creds.data["apikey"]}")
}

# AWS Secrets Manager – Stores auto-generated elasticsearch credentials during the deployment
resource "aws_secretsmanager_secret" "es_secrets" {
  name_prefix = "es_secrets"
  depends_on = [ec_deployment.ec_minimal]
}

resource "aws_secretsmanager_secret_version" "es_credentials" {
  secret_id = aws_secretsmanager_secret.es_secrets.id
  secret_string = <<EOF
  {
    "elasticsearch_username": "${ec_deployment.ec_minimal.elasticsearch_username}",
    "elasticsearch_password": "${ec_deployment.ec_minimal.elasticsearch_password}"
  }
EOF
  depends_on = [aws_secretsmanager_secret.es_secrets]
}

# Vault – Reads AWS credentials if Vault server URL is provided
data "vault_generic_secret" "aws_creds" {
  path = var.vault_aws_path
}

# Vault – Reads ESS credentials if Vault server URL is provided
data "vault_generic_secret" "ess_creds" {
  path = var.vault_ess_path
}