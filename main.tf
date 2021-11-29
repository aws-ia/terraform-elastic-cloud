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

# Create the keystore secret entry (if s3 access key is provided)
resource "ec_deployment_elasticsearch_keystore" "secure_url" {
  count = var.snapshot_s3_access_key_id != "" ? 1 : 0
  deployment_id = ec_deployment.ec_minimal.id
  setting_name  = var.snapshot_s3_access_key_id
  value         = var.snapshot_s3_secret_access_key
}

# Create a local snapshot repository and point to s3 (if local es url is provided)
resource "elasticsearch_snapshot_repository" "repo" {
  count = var.local_elasticsearch_url != "" ? 1 : 0
  depends_on = [aws_s3_bucket.es_s3_snapshot, aws_iam_role.es_role]
  name = "local-es-index-backups"
  type = "s3"
  settings = {
    bucket   = aws_s3_bucket.es_s3_snapshot.id
    region   = var.region
    role_arn = aws_iam_role.es_role[0].arn
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