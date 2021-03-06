terraform {
  # The Elastic Cloud provider is supported from ">=0.13"
  # Version later than 0.13 is required for this terraform block to work
  required_version = ">= 0.13"
  required_providers {
    ec = {
      source  = "elastic/ec"
      version = ">= 0.3.0"
    }
    aws = {
      source = "hashicorp/aws"
      version = ">= 3.73.0"
    }
    random = {
      source = "hashicorp/random"
      version = ">= 2.3.0"
    }
    vault = {
      source = "hashicorp/vault"
      version = "3.3.0"
    }
    elasticsearch = {
      source = "phillbaker/elasticsearch"
      version = "2.0.0-beta.2"
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

# Vault
provider "vault" {
  address = var.vault_address
}