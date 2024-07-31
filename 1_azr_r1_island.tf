resource "random_integer" "island_example" {
  min = 10000
  max = 99999
}

resource "null_resource" "island_always_run" {
  triggers = {
    timestamp = "${timestamp()}"
  }
}

output "island_random_integer" {
  value = random_integer.island_example.result
}

resource "azurerm_resource_group" "island_vms_rg" {
  location = var.azr_r1_location
  name     = "island-vms-rg"
}


resource "azurerm_storage_account" "island_aci_sa" {
  name                     = "acisa${random_integer.island_example.result}"
  resource_group_name      = azurerm_resource_group.island_vms_rg.name
  location                 = var.azr_r1_location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
}

resource "azurerm_storage_share" "island_aci_share" {
  name                 = "aci-config"
  storage_account_name = azurerm_storage_account.island_aci_sa.name
  quota                = 1
}

resource "local_file" "island_config_yaml" {
  filename = "island-config.yaml"
  content = templatefile("${path.module}/1_azr_r1_island_config.tpl",
    { "customer_name"        = var.customer_name,
      "application_2"        = var.application_2,
      "customer_website_url" = var.customer_website_url
    }
  )
}


resource "azurerm_storage_share_file" "island_config_file" {
  name             = "config.yaml"
  content_type     = "text/yaml"
  source           = local_file.island_config_yaml.filename
  storage_share_id = azurerm_storage_share.island_aci_share.id
  lifecycle {
    replace_triggered_by = [null_resource.island_always_run]
  }
}

resource "azurerm_container_group" "island_container_group" {
  name                = "${var.application_1}-cg"
  resource_group_name = azurerm_resource_group.island_vms_rg.name
  location            = var.azr_r1_location
  depends_on          = [azurerm_subnet.r1-azure-spoke-island-aci-subnet, azurerm_storage_share_file.island_config_file]

  container {
    name   = "gatus"
    image  = "docker.io/aweiss4876/gatus-aviatrix:latest"
    cpu    = "1"
    memory = "1.5"
    ports {
      port     = 8080
      protocol = "TCP"
    }
    volume {
      name                 = "config"
      share_name           = "aci-config"
      mount_path           = "/config"
      storage_account_key  = azurerm_storage_account.island_aci_sa.primary_access_key
      storage_account_name = azurerm_storage_account.island_aci_sa.name
    }
  }
  exposed_port = [{
    port     = 8080
    protocol = "TCP"
  }]
  ip_address_type = "Private"
  subnet_ids      = [azurerm_subnet.r1-azure-spoke-island-aci-subnet.id]
  os_type         = "Linux"
}

resource "aviatrix_smart_group" "island" {
  name = "${var.application_1}-app"
  selector {
    match_expressions {
      cidr = azurerm_subnet.r1-azure-spoke-island-aci-subnet.address_prefixes[0]
    }
  }
}

resource "aviatrix_web_group" "allowed_domains" {
  name = "allowed-domains"
  selector {
    match_expressions {
      snifilter = var.customer_website
    }
  }
}

resource "aviatrix_web_group" "allowed_urls" {
  name = "allowed-urls"
  selector {
    match_expressions {
      urlfilter = "https://github.com/AviatrixSystems"
    }
  }
}
