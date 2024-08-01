resource "azurerm_resource_group" "azr_r1_spoke_app1_nata_rg" {
  name     = "azr-${var.azr_r1_location_short}-snata-${var.application_1}-${var.customer_name}-rg"
  location = var.azr_r1_location
}

module "azr_r1_spoke_app1_nata" {
  source  = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version = "1.6.7"

  cloud                            = "Azure"
  name                             = "azr-${var.azr_r1_location_short}-snata-${var.application_1}-${var.customer_name}"
  cidr                             = var.azr_r1_spoke_app1_nat_cidr
  region                           = var.azr_r1_location
  account                          = var.azr_account
  transit_gw                       = module.transits.region_transit_map["${var.azr_r1_location}"][1]
  attached                         = true
  ha_gw                            = false
  single_az_ha                     = false
  included_advertised_spoke_routes = "${var.azr_r1_spoke_app1_nata_advertised_ip}/32"
  resource_group                   = azurerm_resource_group.azr_r1_spoke_app1_nata_rg.name
}

resource "azurerm_resource_group" "azr_r1_spoke_app1_natb_rg" {
  name     = "azr-${var.azr_r1_location_short}-snatb-${var.application_1}-${var.customer_name}-rg"
  location = var.azr_r1_location
}


module "azr_r1_spoke_app1_natb" {
  source  = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version = "1.6.7"

  cloud                            = "Azure"
  name                             = "azr-${var.azr_r1_location_short}-snatb-${var.application_1}-${var.customer_name}"
  cidr                             = var.azr_r1_spoke_app1_nat_cidr
  region                           = var.azr_r1_location
  account                          = var.azr_account
  transit_gw                       = module.transits.region_transit_map["${var.azr_r1_location}"][1]
  attached                         = true
  ha_gw                            = false
  single_az_ha                     = false
  included_advertised_spoke_routes = "${var.azr_r1_spoke_app1_natb_advertised_ip}/32"
  depends_on                       = [module.azr_r1_spoke_app1_nata_rules]
  resource_group                   = azurerm_resource_group.azr_r1_spoke_app1_natb_rg.name
}

## Deploy Linux as Application 1 server


module "azr_r1_app1_vm_nata" {
  source      = "github.com/alexandreweiss/misc-tf-modules/azr-linux-vm-pwd"
  environment = "${var.application_1}-nat-a"
  tags = {
    "application" = var.application_1
  }
  location            = var.azr_r1_location
  location_short      = var.azr_r1_location_short
  index_number        = 01
  subnet_id           = module.azr_r1_spoke_app1_nata.vpc.private_subnets[0].subnet_id
  resource_group_name = azurerm_resource_group.azr_r1_spoke_app1_nata_rg.name
  customer_name       = var.customer_name
  admin_password      = var.vm_password
}

module "azr_r1_app1_vm_natb" {
  source      = "github.com/alexandreweiss/misc-tf-modules/azr-linux-vm-pwd"
  environment = "${var.application_1}-nat-b"
  tags = {
    "application" = var.application_1
  }
  location            = var.azr_r1_location
  location_short      = var.azr_r1_location_short
  index_number        = 01
  subnet_id           = module.azr_r1_spoke_app1_natb.vpc.private_subnets[0].subnet_id
  resource_group_name = azurerm_resource_group.azr_r1_spoke_app1_natb_rg.name
  customer_name       = var.customer_name
  admin_password      = var.vm_password
}

# NAT rule configuration for each spoke
module "azr_r1_spoke_app1_nata_rules" {
  source  = "terraform-aviatrix-modules/mc-overlap-nat-spoke/aviatrix"
  version = "1.1.1"

  #Tip, use count on the module to create or destroy the NAT rules based on spoke gateway attachement
  #Example: count = var.attached ? 1 : 0 #Deploys the module only if var.attached is true.

  spoke_gw_object = module.azr_r1_spoke_app1_nata.spoke_gateway
  spoke_cidrs     = [var.azr_r1_spoke_app1_nat_cidr]
  transit_gw_name = module.transits.region_transit_map["${var.azr_r1_location}"][1]
  gw1_snat_addr   = var.azr_r1_spoke_app1_nata_advertised_ip
  dnat_rules = {
    rule1 = {
      dst_cidr  = "${var.azr_r1_spoke_app1_nata_advertised_ip}/32",
      dst_port  = "22",
      protocol  = "tcp",
      dnat_ips  = module.azr_r1_app1_vm_nata.vm_private_ip,
      dnat_port = "22",
    }
  }
  depends_on = [module.azr_r1_spoke_app1_nata]
}

module "azr_r1_spoke_app1_natb_rules" {
  source  = "terraform-aviatrix-modules/mc-overlap-nat-spoke/aviatrix"
  version = "1.1.1"

  #Tip, use count on the module to create or destroy the NAT rules based on spoke gateway attachement
  #Example: count = var.attached ? 1 : 0 #Deploys the module only if var.attached is true.

  spoke_gw_object = module.azr_r1_spoke_app1_natb.spoke_gateway
  spoke_cidrs     = [var.azr_r1_spoke_app1_nat_cidr]
  transit_gw_name = module.transits.region_transit_map["${var.azr_r1_location}"][1]
  gw1_snat_addr   = var.azr_r1_spoke_app1_natb_advertised_ip
  dnat_rules = {
    rule1 = {
      dst_cidr  = "${var.azr_r1_spoke_app1_natb_advertised_ip}/32",
      dst_port  = "22",
      protocol  = "tcp",
      dnat_ips  = module.azr_r1_app1_vm_natb.vm_private_ip,
      dnat_port = "22",
    }
  }
  depends_on = [module.azr_r1_spoke_app1_natb]
}
