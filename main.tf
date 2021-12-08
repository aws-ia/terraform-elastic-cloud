# Retrieve the latest stack pack version
data "ec_stack" "latest" {
  version_regex = "latest"
  region        = var.region
}

# Create an Elastic Cloud deployment
resource "ec_deployment" "ec_minimal" {
  # Optional name
  name = var.name

  # Mandatory fields
  region                 = var.region
  version                = data.ec_stack.latest.version
  deployment_template_id = var.deployment_template_id
  traffic_filter         = [ec_deployment_traffic_filter.allow_all.id]

  elasticsearch {
    autoscale = var.autoscale

    /*
    snapshot_source {
      source_elasticsearch_cluster_id = "cluster_uuid"
    }
    */
  }

  tags = {
    owner     = "elastic cloud"
    component = "search"
  }

  kibana {}

  apm {}

  enterprise_search {
    topology {
      zone_count = var.zone_count
    }
  }
}

# Create a secure keystore for ec deployment to access a snapshot S3 bucket (if s3 access key is provided)
resource "ec_deployment_elasticsearch_keystore" "access_key" {
  count = var.s3_client_access_key != "" ? 1 : 0
  deployment_id = ec_deployment.ec_minimal.id
  setting_name  = "s3.client.default.access_key"
  value         = var.s3_client_access_key
}

# Create a secure keystore for ec deployment to access a snapshot S3 bucket (if s3 access key is provided)
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
    curl -v XPUT   "${var.local_elasticsearch_url}/_snapshot/${var.local_elasticsearch_repo_name}/es-snapshot-${random_id.id.dec}?wait_for_completion=true" -H 'Content-Type: application/json' -d '
{
  "indices": "*",
  "ignore_unavailable": true,
  "include_global_state": false
}
'
EOT
  }
}

# Create a repo on Elastic Cloud and points to the S3 bucket
resource "null_resource" "create_cloud_repo" {
  depends_on = [null_resource.create_snapshot]
  provisioner "local-exec" {
    command=<<EOT
    curl -v XPUT -u ${ec_deployment.ec_minimal.elasticsearch_username}:${ec_deployment.ec_minimal.elasticsearch_password}  "${ec_deployment.ec_minimal.elasticsearch[0].https_endpoint}/_snapshot/repository_${var.local_elasticsearch_repo_name}" -H 'Content-Type: application/json' -d '
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

# Create an Elastic Cloud traffic filter
resource "ec_deployment_traffic_filter" "allow_all" {
  name   = "Allow all ip addresses"
  type   = "ip"
  region = var.region

  rule {
    source = var.sourceip
  }
}

resource "random_id" "id" {
	  byte_length = 8
}