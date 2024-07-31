terraform {
  required_providers {
    aviatrix = {
      source = "aviatrixsystems/aviatrix"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
  }
  # cloud {
  #   organization = "ananableu"
  #   workspaces {
  #     name = "crl-demo"
  #   }
  # }
}

provider "aviatrix" {
  controller_ip = var.controller_ip
  password      = var.admin_password
  username      = "admin"
}

provider "azurerm" {
  features {

  }
}

provider "aws" {
  region = "eu-central-1"
  alias  = "r1"
}

provider "aws" {
  region = "eu-west-3"
  alias  = "r2"
}

