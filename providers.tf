terraform {
  # The Elastic Cloud provider is supported from ">=0.12"
  # Version later than 0.12.29 is required for this terraform block to work
  required_version = ">= 0.12.29"
  required_providers {
    ec = {
      source  = "elastic/ec"
      version = "0.3.0"
    }
  }
}

provider "ec" {
  # Configuration options
  apikey = var.apikey
}