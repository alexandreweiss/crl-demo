module "azr_r2_spoke_app1" {
  source  = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version = "1.6.7"

  cloud          = "Azure"
  name           = "azr-${var.azr_r2_location_short}-spoke-${var.application_1}-${var.customer_name}"
  cidr           = var.azr_r2_spoke_app1_cidr
  region         = var.azr_r2_location
  account        = var.azr_account
  transit_gw     = module.transits.region_transit_map["${var.azr_r2_location}"][0]
  attached       = true
  ha_gw          = false
  single_az_ha   = false
  single_ip_snat = true
}

## Deploy Linux as Application 1 server

data "aviatrix_vpc" "azr_r2_spoke_app1_vpc" {
  depends_on = [module.azr_r2_spoke_app1]
  name       = module.azr_r2_spoke_app1.vpc.name
}

data "template_file" "azr_r2_app1_vm_config" {
  template = file("${path.module}/2_config_azr_r2_app1_vm.tpl")

  vars = {
    "application_1" = var.application_1
    "region"        = var.azr_r2_location
  }
}

module "azr_r2_app1_vm" {
  source      = "github.com/alexandreweiss/misc-tf-modules/azr-linux-vm-pwd"
  environment = var.application_1
  tags = {
    "application" = var.application_1
  }
  location            = var.azr_r2_location
  location_short      = var.azr_r2_location_short
  index_number        = 01
  subnet_id           = module.azr_r2_spoke_app1.vpc.private_subnets[0].subnet_id
  resource_group_name = data.aviatrix_vpc.azr_r2_spoke_app1_vpc.resource_group
  customer_name       = var.customer_name
  admin_password      = var.vm_password
  custom_data         = base64encode(data.template_file.azr_r2_app1_vm_config.rendered)
}



module "azr_r2_spoke_app2" {
  source  = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version = "1.6.7"

  cloud        = "Azure"
  name         = "azr-${var.azr_r2_location_short}-spoke-${var.application_2}-${var.customer_name}"
  cidr         = var.azr_r2_spoke_app2_cidr
  region       = var.azr_r2_location
  account      = var.azr_account
  transit_gw   = module.transits.region_transit_map[var.azr_r2_location][0]
  attached     = true
  ha_gw        = false
  single_az_ha = false
}

## Deploy Linux as Application 2 server
# resource "azurerm_resource_group" "azr_r2_spoke_app2_rg" {
#   location = var.azr_r2_location
#   name     = "azr-${var.azr_r2_location_short}-spoke-${var.application_2}-${var.customer_name}-rg"
# }

data "aviatrix_vpc" "azr_r2_spoke_app2_vpc" {
  depends_on = [module.azr_r2_spoke_app2]
  name       = module.azr_r2_spoke_app2.vpc.name
}

module "azr_r2_app2_vm" {
  source      = "github.com/alexandreweiss/misc-tf-modules/azr-linux-vm-pwd"
  environment = var.application_2
  tags = {
    "application" = var.application_2
  }
  location            = var.azr_r2_location
  location_short      = var.azr_r2_location_short
  index_number        = 01
  subnet_id           = module.azr_r2_spoke_app2.vpc.private_subnets[0].subnet_id
  resource_group_name = data.aviatrix_vpc.azr_r2_spoke_app2_vpc.resource_group
  customer_name       = var.customer_name
  admin_password      = var.vm_password
  depends_on = [
  ]
}
