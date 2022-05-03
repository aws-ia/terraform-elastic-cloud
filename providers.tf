terraform {
  # The Elastic Cloud provider is supported from ">=0.13"
  # Version later than 0.13 is required for this terraform block to work
  required_version = ">= 0.13"
  required_providers {
    ec = {
      source  = "elastic/ec"
      version = ">= 0.4.0"
    }
    aws = {
      source = "hashicorp/aws"
      version = ">= 4.12.1"
    }
    random = {
      source = "hashicorp/random"
      version = ">= 3.1.3"
    }
    vault = {
      source = "hashicorp/vault"
      version = "3.5.0"
    }
    elasticsearch = {
      source = "phillbaker/elasticsearch"
      version = "2.0.1"
    }
  }
}

provider "ec" {
  apikey = local.ess_api_key
}

provider "aws" {
  profile = "default"
  region  = var.region
}

provider "elasticsearch" {
  url = var.local_elasticsearch_url
}