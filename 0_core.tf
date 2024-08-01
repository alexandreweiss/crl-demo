module "key_pair_r1" {
  source = "terraform-aws-modules/key-pair/aws"

  key_name           = "aviatrix_${var.aws_r1_location_short}-${var.customer_name}"
  create_private_key = true
}

module "key_pair_r2" {
  source = "terraform-aws-modules/key-pair/aws"
  providers = {
    aws = aws.r2
  }

  key_name           = "aviatrix_${var.aws_r2_location_short}-${var.customer_name}"
  create_private_key = true
}

# Firenet Palo bootstrap material
resource "random_integer" "random_rg" {
  min = 10000
  max = 99999
}

resource "azurerm_resource_group" "core_rg" {
  location = var.azr_r1_location
  name     = "core-${random_integer.random_rg.result}-rg"
}

resource "azurerm_storage_account" "palo_bootstrap_sa" {
  name                     = "avxsa${random_integer.random_rg.result}"
  resource_group_name      = azurerm_resource_group.core_rg.name
  location                 = var.azr_r1_location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
}

resource "azurerm_storage_share" "palo_bootstrap_share" {
  name                 = "pan-bootstrap"
  storage_account_name = azurerm_storage_account.palo_bootstrap_sa.name
  quota                = 1
}

#create a loop to create 4 folders in the share : config, content, software, license
resource "azurerm_storage_share_directory" "palo_bootstrap_share_dir" {
  for_each         = toset(["config", "content", "software", "license"])
  name             = each.value
  storage_share_id = azurerm_storage_share.palo_bootstrap_share.id
}


resource "azurerm_storage_share_file" "palo_bootstrap_xml" {
  name             = "config/bootstrap.xml"
  content_type     = "text/xml"
  source           = "bootstrap.xml"
  storage_share_id = azurerm_storage_share.palo_bootstrap_share.id
  # lifecycle {
  #   replace_triggered_by = [null_resource.island_always_run]
  # }
  depends_on = [azurerm_storage_share_directory.palo_bootstrap_share_dir]
}

resource "azurerm_storage_share_file" "palo_init_cfg" {
  name             = "config/init-cfg.txt"
  content_type     = "text/plain"
  source           = "init-cfg.txt"
  storage_share_id = azurerm_storage_share.palo_bootstrap_share.id
  # lifecycle {
  #   replace_triggered_by = [null_resource.island_always_run]
  # }
  depends_on = [azurerm_storage_share_directory.palo_bootstrap_share_dir]
}

## Linux image search
data "aws_ami" "ubuntu_r1" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/*ubuntu-jammy-22.04-amd64-server-*"]
  }
}

## Linux image search
data "aws_ami" "ubuntu_r2" {
  most_recent = true
  provider    = aws.r2
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/*ubuntu-jammy-22.04-amd64-server-*"]
  }
}
