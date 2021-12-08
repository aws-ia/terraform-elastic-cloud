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

    snapshot_source {
      source_elasticsearch_cluster_id = "<id-es-cluster>"
    }
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
resource "ec_deployment_elasticsearch_keystore" "secure_url" {
  count = var.snapshot_s3_access_key_id != "" ? 1 : 0
  depends_on = [aws_s3_bucket.es_s3_snapshot]
  deployment_id = ec_deployment.ec_minimal.id
  setting_name  = var.snapshot_s3_access_key_id
  value         = var.snapshot_s3_secret_access_key
}

# Create a local snapshot repository and point to an existing S3 bucket (if local es url is provided)
resource "elasticsearch_snapshot_repository" "repo_existing_s3" {
  count = var.local_elasticsearch_url != "" && var.existing_snapshot_s3_bucket_name != "" ? 1 : 0
  name = var.snapshot_local_repo_name
  type = "s3"
  settings = {
    bucket   = var.existing_snapshot_s3_bucket_name
    region   = var.region
    role_arn = aws_iam_role.es_role.arn
  }
}

# Create a local snapshot repository and point to a new S3 bucket (if local es url is provided)
resource "elasticsearch_snapshot_repository" "repo_new_s3" {
  count = var.local_elasticsearch_url != "" && var.existing_snapshot_s3_bucket_name == "" ? 1 : 0
  depends_on = [aws_s3_bucket.es_s3_snapshot, aws_iam_role.es_role]
  name = var.snapshot_local_repo_name
  type = "s3"
  settings = {
    bucket   = aws_s3_bucket.es_s3_snapshot.id
    region   = var.region
    role_arn = aws_iam_role.es_role.arn
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