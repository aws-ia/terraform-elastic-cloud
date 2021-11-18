# Retrieve the latest stack pack version
data "ec_stack" "latest" {
  version_regex = "latest"
  region        = var.region
}

# Create an Elastic Cloud deployment
resource "ec_deployment" "example_minimal" {
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

# Create a local snapshot repository and point to s3
resource "elasticsearch_snapshot_repository" "repo" {
  count = var.local_elasticsearch_url != "" ? 1 : 0
  name = "es-index-backups"
  type = "s3"
  settings = {
    bucket   = "es-index-backups"
    region   = var.region
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