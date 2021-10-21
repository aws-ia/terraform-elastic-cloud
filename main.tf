terraform {
  required_providers {
    ec = {
      source = "elastic/ec"
      version = "0.3.0"
    }
  }
}

provider "ec" {
  # Configuration options
  apikey = var.apikey
}


data "ec_stack" "latest" {
  version_regex = "latest"
  region        = var.region
}

resource "ec_deployment" "example_minimal" {
  # Optional name.
  name = var.name

  # Mandatory fields
  region                 = var.region
  version                = data.ec_stack.latest.version
  deployment_template_id = var.deployment_template_id

  elasticsearch {}

  kibana {}

  apm {}

  enterprise_search {}
}