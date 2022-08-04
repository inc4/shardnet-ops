terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "inc4"

    workspaces {
      name = "shardnet-ops"
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.22.0"
    }
  }
}
