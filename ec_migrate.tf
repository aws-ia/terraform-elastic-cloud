locals {
  es_snapshot_name = "es-snapshot-${random_id.id.dec}"
}

# Create a random id
resource "random_id" "id" {
  byte_length = 8
}

# Add an access key to Elastic Cloud keystore to access a snapshot S3 bucket (if s3 access key is provided)
resource "ec_deployment_elasticsearch_keystore" "access_key" {
  count         = local.aws_access_key != null ? 1 : 0
  deployment_id = ec_deployment.ec_minimal.id
  setting_name  = "s3.client.default.access_key"
  value         = local.aws_access_key
}

# Add a secret key to Elastic Cloud keystore to access a snapshot S3 bucket (if s3 access key is provided)
resource "ec_deployment_elasticsearch_keystore" "secret_key" {
  count         = local.aws_secret_key != null ? 1 : 0
  deployment_id = ec_deployment.ec_minimal.id
  setting_name  = "s3.client.default.secret_key"
  value         = local.aws_secret_key
}

# Create a local repository and point to an S3 bucket (if local es url is provided)
resource "elasticsearch_snapshot_repository" "create_local_repo" {
  count = var.local_elasticsearch_url != "" ? 1 : 0

  name = var.local_elasticsearch_repo_name
  type = "s3"
  settings = {
    bucket   = var.existing_s3_repo_bucket_name != "" ? var.existing_s3_repo_bucket_name : aws_s3_bucket.es_s3_repo.id
    region   = var.region
    role_arn = aws_iam_role.es_role.arn
  }

  depends_on = [aws_iam_role.es_role]
}

# Create a local one-off snapshot on the S3 repository (if local es url is provided)
resource "null_resource" "create_snapshot" {
  count = var.local_elasticsearch_url != "" ? 1 : 0

  provisioner "local-exec" {
    command = <<EOT
curl -v XPUT "${var.local_elasticsearch_url}/_snapshot/${var.local_elasticsearch_repo_name}/${local.es_snapshot_name}?wait_for_completion=true" -H 'Content-Type: application/json' -d '
{
  "indices": "*",
  "ignore_unavailable": true,
  "include_global_state": true
}
'
EOT
  }

  depends_on = [elasticsearch_snapshot_repository.create_local_repo]
}

# Create a repository on Elastic Cloud and points to the S3 bucket
resource "null_resource" "create_cloud_repo" {
  count = var.local_elasticsearch_url != "" ? 1 : 0

  provisioner "local-exec" {
    command = <<EOT
curl -v XPUT -u ${ec_deployment.ec_minimal.elasticsearch_username}:${ec_deployment.ec_minimal.elasticsearch_password}  "${ec_deployment.ec_minimal.elasticsearch[0].https_endpoint}/_snapshot/${var.local_elasticsearch_repo_name}" -H 'Content-Type: application/json' -d '
{
  "type": "s3",
  "settings": {
    "bucket": "${var.existing_s3_repo_bucket_name != "" ? var.existing_s3_repo_bucket_name : aws_s3_bucket.es_s3_repo.id}",
    "region": "${var.region}"
  }
}
'
EOT
  }

  depends_on = [ec_deployment.ec_minimal, null_resource.create_snapshot]
}

# Check the Elastic Cloud repository status until it becomes available
resource "null_resource" "restore_snapshot" {
  count = var.local_elasticsearch_url != "" ? 1 : 0

  triggers = {
    status = length(regexall(".*nodes.*", file("./ec_repo.status"))) > 0
  }

  provisioner "local-exec" {
    command = data.template_file.run_rest_api.rendered
  }
}

# Run REST API
data "template_file" "run_rest_api" {
  template = file("ec_rest_api.sh")
  vars = {
    ec-user     = local.es_credentials.elasticsearch_username
    ec-pwd      = local.es_credentials.elasticsearch_password
    ec-url      = ec_deployment.ec_minimal.elasticsearch[0].https_endpoint
    ec-repo     = var.local_elasticsearch_repo_name
    ec-snapshot = local.es_snapshot_name
  }
}