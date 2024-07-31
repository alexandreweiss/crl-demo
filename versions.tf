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
  cloud {
    organization = "ananableu"
    workspaces {
      name = "acp-demo"
    }
  }
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
