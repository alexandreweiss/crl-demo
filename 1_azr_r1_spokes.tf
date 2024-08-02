resource "azurerm_resource_group" "azr_r1_spoke_app1_rg" {
  name     = "azr-${var.azr_r1_location_short}-spoke-${var.application_1}-${var.customer_name}-rg"
  location = var.azr_r1_location
}

module "azr_r1_spoke_app1" {
  source  = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version = "1.6.7"

  cloud             = "Azure"
  name              = "azr-${var.azr_r1_location_short}-spoke-${var.application_1}-${var.customer_name}"
  resource_group    = azurerm_resource_group.azr_r1_spoke_app1_rg.name
  cidr              = var.azr_r1_spoke_app1_cidr
  region            = var.azr_r1_location
  account           = var.azr_account
  transit_gw        = module.transits.region_transit_map["${var.azr_r1_location}"][1]
  transit_gw_egress = module.transits.region_transit_map["${var.azr_r1_location}"][0]
  attached          = true
  ha_gw             = false
  single_az_ha      = false
  single_ip_snat    = false
}

## Deploy Linux as Application 1 server

data "template_file" "azr_r1_app1_vm_config" {
  template = file("${path.module}/1_config_azr_r1_app1_vm.tpl")

  vars = {
    storage_account_pe_ip   = azurerm_private_endpoint.storage_account_pe.private_service_connection.0.private_ip_address
    storage_account_name    = azurerm_storage_account.storage_account.name
    storage_account_key     = azurerm_storage_account.storage_account.primary_access_key
    storage_file_share_name = azurerm_storage_share.data.name
  }
}

module "azr_r1_app1_vm" {
  source      = "github.com/alexandreweiss/misc-tf-modules/azr-linux-vm-pwd"
  environment = var.application_1
  tags = {
    "application" = var.application_1
  }
  location            = var.azr_r1_location
  location_short      = var.azr_r1_location_short
  index_number        = 01
  subnet_id           = module.azr_r1_spoke_app1.vpc.private_subnets[0].subnet_id
  resource_group_name = azurerm_resource_group.azr_r1_spoke_app1_rg.name
  customer_name       = var.customer_name
  admin_password      = var.vm_password
  custom_data         = base64encode(data.template_file.azr_r1_app1_vm_config.rendered)

  depends_on = [module.azr_r1_spoke_app1]
}

resource "azurerm_resource_group" "azr_r1_spoke_app2_rg" {
  name     = "azr-${var.azr_r1_location_short}-spoke-${var.application_2}-${var.customer_name}-rg"
  location = var.azr_r1_location
}

module "azr_r1_spoke_app2" {
  source  = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version = "1.6.7"

  cloud             = "Azure"
  name              = "azr-${var.azr_r1_location_short}-spoke-${var.application_2}-${var.customer_name}"
  resource_group    = azurerm_resource_group.azr_r1_spoke_app2_rg.name
  cidr              = var.azr_r1_spoke_app2_cidr
  region            = var.azr_r1_location
  account           = var.azr_account
  transit_gw        = module.transits.region_transit_map["${var.azr_r1_location}"][1]
  transit_gw_egress = module.transits.region_transit_map["${var.azr_r1_location}"][0]
  attached          = true
  ha_gw             = false
  single_az_ha      = false
  single_ip_snat    = false
}

## Deploy Linux as Application 2 server

module "azr_r1_app2_vm" {
  source      = "github.com/alexandreweiss/misc-tf-modules/azr-linux-vm-pwd"
  environment = var.application_2
  tags = {
    "application" = var.application_2
  }
  location            = var.azr_r1_location
  location_short      = var.azr_r1_location_short
  index_number        = 01
  subnet_id           = module.azr_r1_spoke_app2.vpc.private_subnets[0].subnet_id
  resource_group_name = azurerm_resource_group.azr_r1_spoke_app2_rg.name
  customer_name       = var.customer_name
  admin_password      = var.vm_password
}

## Storage account and prviate endpoint for Azure Blob Storage
# Add a storage account and private endpoint for Azure Blob Storage using azurerm_storage_account and azurerm_private_endpoint resources

resource "random_integer" "sa_random_suffix" {
  min = 10000
  max = 99999
}

resource "azurerm_storage_account" "storage_account" {
  name                      = "azr${var.azr_r1_location_short}${var.customer_name}sa${random_integer.sa_random_suffix.result}"
  resource_group_name       = azurerm_resource_group.azr_r1_spoke_app2_rg.name
  location                  = var.azr_r1_location
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  enable_https_traffic_only = true
}

resource "azurerm_private_endpoint" "storage_account_pe" {
  name                = "azr${var.azr_r1_location_short}${var.customer_name}file"
  location            = var.azr_r1_location
  resource_group_name = azurerm_resource_group.azr_r1_spoke_app2_rg.name
  subnet_id           = module.azr_r1_spoke_app2.vpc.private_subnets[0].subnet_id

  private_service_connection {
    name                           = "azr${var.azr_r1_location_short}${var.customer_name}safile"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.storage_account.id
    subresource_names              = ["file"]
  }
}

# Add a filesystem to the storage account named "data"
resource "azurerm_storage_share" "data" {
  name                 = "data"
  storage_account_name = azurerm_storage_account.storage_account.name
  quota                = 50
}
