locals {
    es_snapshot_name = "es-snapshot-${random_id.id.dec}"
}

# Create a random id
resource "random_id" "id" {
	  byte_length = 8
}

# Create a timer for creation
resource "time_sleep" "wait_5_minutes" {
  create_duration = "300s"
}

# Add an access key to Elastic Cloud keystore to access a snapshot S3 bucket (if s3 access key is provided)
resource "ec_deployment_elasticsearch_keystore" "access_key" {
  count = var.s3_client_access_key != "" ? 1 : 0
  deployment_id = ec_deployment.ec_minimal.id
  setting_name  = "s3.client.default.access_key"
  value         = var.s3_client_access_key
}

# Add a secret key to Elastic Cloud keystore to access a snapshot S3 bucket (if s3 access key is provided)
resource "ec_deployment_elasticsearch_keystore" "secret_key" {
  count = var.s3_client_secret_key != "" ? 1 : 0
  deployment_id = ec_deployment.ec_minimal.id
  setting_name  = "s3.client.default.secret_key"
  value         = var.s3_client_secret_key
}

# Create a local repository and point to an S3 bucket (if local es url is provided)
resource "elasticsearch_snapshot_repository" "create_local_repo" {
  count = var.local_elasticsearch_url != "" ? 1 : 0
  depends_on = [aws_iam_role.es_role]
  name = var.local_elasticsearch_repo_name
  type = "s3"
  settings = {
    bucket   = var.existing_snapshot_s3_bucket_name != "" ? var.existing_snapshot_s3_bucket_name : aws_s3_bucket.es_s3_snapshot.id
    region   = var.region
    role_arn = aws_iam_role.es_role.arn
  }
}

# Create a local one-off snapshot on the S3 repository (if local es url is provided)
resource "null_resource" "create_snapshot" {
  count = var.local_elasticsearch_url != "" ? 1 : 0
  depends_on = [elasticsearch_snapshot_repository.create_local_repo]
  provisioner "local-exec" {
    command=<<EOT
curl -v XPUT "${var.local_elasticsearch_url}/_snapshot/${var.local_elasticsearch_repo_name}/${local.es_snapshot_name}?wait_for_completion=true" -H 'Content-Type: application/json' -d '
{
  "indices": "*",
  "ignore_unavailable": true,
  "include_global_state": true
}
'
EOT
  }
}

# Create a repository on Elastic Cloud and points to the S3 bucket
resource "null_resource" "create_cloud_repo" {
  depends_on = [ec_deployment.ec_minimal, null_resource.create_snapshot, time_sleep.wait_5_minutes]
  provisioner "local-exec" {
    command=<<EOT
curl -v XPUT -u ${ec_deployment.ec_minimal.elasticsearch_username}:${ec_deployment.ec_minimal.elasticsearch_password}  "${ec_deployment.ec_minimal.elasticsearch[0].https_endpoint}/_snapshot/${var.local_elasticsearch_repo_name}" -H 'Content-Type: application/json' -d '
{
  "type": "s3",
  "settings": {
    "bucket": "${aws_s3_bucket.es_s3_snapshot.id}",
    "region": "${var.region}"
  }
}
'
EOT
  }
}

# Restore the Elastic Cloud cluster from the snapshot on S3 bucket
resource "null_resource" "restore_snapshot" {
  depends_on = [null_resource.create_cloud_repo]
  provisioner "local-exec" {
    command=<<-EOT
curl -v XPOST -u ${ec_deployment.ec_minimal.elasticsearch_username}:${ec_deployment.ec_minimal.elasticsearch_password}  "${ec_deployment.ec_minimal.elasticsearch[0].https_endpoint}/*/_close?expand_wildcards=all"
curl -v XPOST -u ${ec_deployment.ec_minimal.elasticsearch_username}:${ec_deployment.ec_minimal.elasticsearch_password}  "${ec_deployment.ec_minimal.elasticsearch[0].https_endpoint}/_snapshot/${var.local_elasticsearch_repo_name}/${local.es_snapshot_name}/_restore?wait_for_completion=true" -H 'Content-Type: application/json' -d '
{
  "indices": "*",
  "ignore_unavailable": true,
  "include_global_state": true,
  "rename_pattern": ".geoip_databases",
  "rename_replacement": ".geoip_databases_.geoip_databases"
}'
curl -v XPOST -u ${ec_deployment.ec_minimal.elasticsearch_username}:${ec_deployment.ec_minimal.elasticsearch_password}  "${ec_deployment.ec_minimal.elasticsearch[0].https_endpoint}/*/_open?expand_wildcards=all"
EOT
  }
}