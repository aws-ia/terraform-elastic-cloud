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
  apikey = ""

}


data "ec_stack" "latest" {
  version_regex = "latest"
  region        = "us-east-1"
}

resource "ec_deployment" "example_minimal" {
  # Optional name.
  name = "my_example_deployment"

  # Mandatory fields
  region                 = "us-east-1"
  version                = data.ec_stack.latest.version
  deployment_template_id = "aws-io-optimized-v2"

  elasticsearch {}

  kibana {}

  apm {}

  enterprise_search {}
}