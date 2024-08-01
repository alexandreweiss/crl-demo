module "transits" {
  source  = "terraform-aviatrix-modules/backbone/aviatrix"
  version = "1.2.2"

  global_settings = {

    transit_accounts = {
      azure = var.azr_account
      AWS   = var.aws_account
    }

    transit_ha_gw = false

  }

  transit_firenet = {

    transit-azr-r1 = {
      transit_cloud                    = "azure",
      transit_cidr                     = var.azr_r1_transit_cidr,
      transit_region_name              = var.azr_r1_location,
      transit_asn                      = 65101,
      transit_name                     = "azr-${var.azr_r1_location_short}-${var.customer_name}-transit"
      firenet                          = true
      firenet_firewall_image           = "Palo Alto Networks VM-Series Flex Next-Generation Firewall (BYOL)"
      firenet_bootstrap_storage_name_1 = azurerm_storage_account.palo_bootstrap_sa.name
      firenet_file_share_folder_1      = azurerm_storage_share.palo_bootstrap_share.name
      firenet_storage_access_key_1     = azurerm_storage_account.palo_bootstrap_sa.primary_access_key
    },

    transit-azr-egress-r1 = {
      transit_cloud                         = "azure",
      transit_cidr                          = var.azr_r1_egress_transit_cidr,
      transit_region_name                   = var.azr_r1_location,
      transit_asn                           = 65102,
      transit_name                          = "azr-${var.azr_r1_location_short}-${var.customer_name}-egress-transit"
      transit_enable_egress_transit_firenet = true
      firenet                               = true
      firenet_firewall_image                = "Palo Alto Networks VM-Series Flex Next-Generation Firewall (BYOL)"
      firenet_bootstrap_storage_name_1      = azurerm_storage_account.palo_bootstrap_sa.name
      firenet_file_share_folder_1           = azurerm_storage_share.palo_bootstrap_share.name
      firenet_storage_access_key_1          = azurerm_storage_account.palo_bootstrap_sa.primary_access_key
    },

    transit-azr-r2 = {
      transit_cloud       = "azure",
      transit_cidr        = var.azr_transit_r2_cidr,
      transit_region_name = var.azr_r2_location,
      transit_asn         = 65103,
      transit_name        = "azr-${var.azr_r2_location_short}-${var.customer_name}-transit"
    },

    transit-aws-r1 = {
      transit_cloud       = "AWS",
      transit_cidr        = var.aws_r1_transit_cidr,
      transit_region_name = var.aws_r1_location,
      transit_asn         = 65104,
      transit_name        = "aws-${var.aws_r1_location_short}-${var.customer_name}-transit"
    },

    transit-aws-r2 = {
      transit_cloud       = "AWS",
      transit_cidr        = var.aws_r2_transit_cidr,
      transit_region_name = var.aws_r2_location,
      transit_asn         = 65105,
      transit_name        = "aws-${var.aws_r2_location_short}-${var.customer_name}-transit"
    }
    # w-transit-azr-r2b = {
    #   transit_cloud       = "azure",
    #   transit_cidr        = "10.77.0.0/23",
    #   transit_region_name = var.azr_r2_location,
    #   transit_asn         = 65105,
    #   transit_name        = "azr-${var.azr_r2_location_short}-${var.customer_name}-transit-2"
    # },

  }
  depends_on = [azurerm_storage_share_file.palo_bootstrap_xml, azurerm_storage_share_file.palo_init_cfg]
}
