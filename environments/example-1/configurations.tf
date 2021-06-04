terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "your_account"
    workspaces {
      name = "example-1"
    }
  }
  required_providers {
    oci = {
      source  = "hashicorp/oci"
      version = "~> 4.20.0"
    }
  }
}
