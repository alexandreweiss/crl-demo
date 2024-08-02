// APP1 SPOKE in R1

// Replace app1 by app2 as need be
// Replace application_1 by application_2 as need be
// Replace CIDR block as need be 10.10.2 for app1, 10.11.2 for app2 ...

resource "azurerm_resource_group" "azr-r1-spoke-island-rg" {
  location = var.azr_r1_location
  name     = "azr-${var.azr_r1_location_short}-spoke-island-${var.customer_name}-rg"
}

resource "azurerm_virtual_network" "azure-spoke-island-r1" {
  address_space       = ["10.14.2.0/23"]
  location            = var.azr_r1_location
  name                = "azr-${var.azr_r1_location_short}-spoke-island-vn"
  resource_group_name = azurerm_resource_group.azr-r1-spoke-island-rg.name
}

# Comment out for HPE
resource "azurerm_subnet" "r1-azure-spoke-island-gw-subnet" {
  address_prefixes     = ["10.14.2.0/26"]
  name                 = "avx-gw-subnet"
  resource_group_name  = azurerm_resource_group.azr-r1-spoke-island-rg.name
  virtual_network_name = azurerm_virtual_network.azure-spoke-island-r1.name
}

resource "azurerm_subnet" "r1-azure-spoke-island-hagw-subnet" {
  address_prefixes     = ["10.14.2.64/26"]
  name                 = "avx-hagw-subnet"
  resource_group_name  = azurerm_resource_group.azr-r1-spoke-island-rg.name
  virtual_network_name = azurerm_virtual_network.azure-spoke-island-r1.name
}

resource "azurerm_subnet" "r1-azure-spoke-island-vm-subnet" {
  address_prefixes     = ["10.14.2.128/28"]
  name                 = "avx-vm-subnet"
  resource_group_name  = azurerm_resource_group.azr-r1-spoke-island-rg.name
  virtual_network_name = azurerm_virtual_network.azure-spoke-island-r1.name
}

resource "azurerm_route_table" "r1-azure-spoke-island-vm-subnet-rt" {
  location            = var.azr_r1_location
  name                = "azr-${var.azr_r1_location_short}-spoke-island-vm-subnet-rt"
  resource_group_name = azurerm_resource_group.azr-r1-spoke-island-rg.name

  route {
    address_prefix = "0.0.0.0/0"
    name           = "internetDefaultBlackhole"
    next_hop_type  = "None"
  }

  lifecycle {
    ignore_changes = [
      route,
    ]
  }
}

resource "azurerm_subnet" "r1-azure-spoke-island-vm-subnet-2" {
  address_prefixes     = ["10.14.2.144/28"]
  name                 = "avx-vm-subnet-2"
  resource_group_name  = azurerm_resource_group.azr-r1-spoke-island-rg.name
  virtual_network_name = azurerm_virtual_network.azure-spoke-island-r1.name
}


resource "azurerm_subnet" "r1-azure-spoke-island-aci-subnet" {
  address_prefixes     = ["10.14.2.160/28"]
  name                 = "aci-subnet"
  resource_group_name  = azurerm_resource_group.azr-r1-spoke-island-rg.name
  virtual_network_name = azurerm_virtual_network.azure-spoke-island-r1.name
  delegation {
    name = "delegation"
    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_route_table" "r1-azure-spoke-island-vm-subnet-2-rt" {
  location            = var.azr_r1_location
  name                = "azr-${var.azr_r1_location_short}-spoke-island-vm-subnet-2-rt"
  resource_group_name = azurerm_resource_group.azr-r1-spoke-island-rg.name

  route {
    address_prefix = "0.0.0.0/0"
    name           = "internetDefaultBlackhole"
    next_hop_type  = "None"
  }

  lifecycle {
    ignore_changes = [
      route,
    ]
  }
}

resource "azurerm_route_table" "r1-azure-spoke-island-aci-subnet-rt" {
  location            = var.azr_r1_location
  name                = "azr-${var.azr_r1_location_short}-spoke-island-aci-subnet-rt"
  resource_group_name = azurerm_resource_group.azr-r1-spoke-island-rg.name

  route {
    address_prefix = "0.0.0.0/0"
    name           = "internetDefaultBlackhole"
    next_hop_type  = "None"
  }

  lifecycle {
    ignore_changes = [
      route,
    ]
  }
}

resource "azurerm_subnet_route_table_association" "island-subnet-vm-rt-assoc" {
  route_table_id = azurerm_route_table.r1-azure-spoke-island-vm-subnet-rt.id
  subnet_id      = azurerm_subnet.r1-azure-spoke-island-vm-subnet.id
}

resource "azurerm_subnet_route_table_association" "island-subnet-vm-2-rt-assoc" {
  route_table_id = azurerm_route_table.r1-azure-spoke-island-vm-subnet-2-rt.id
  subnet_id      = azurerm_subnet.r1-azure-spoke-island-vm-subnet-2.id
}

resource "azurerm_subnet_route_table_association" "island-subnet-aci-rt-assoc" {
  route_table_id = azurerm_route_table.r1-azure-spoke-island-aci-subnet-rt.id
  subnet_id      = azurerm_subnet.r1-azure-spoke-island-aci-subnet.id
}

module "azr_r1_spoke_island" {
  source  = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version = "1.6.3"

  cloud            = "Azure"
  name             = "azr-${var.azr_r1_location_short}-spoke-island-${var.customer_name}"
  vpc_id           = "${azurerm_virtual_network.azure-spoke-island-r1.name}:${azurerm_resource_group.azr-r1-spoke-island-rg.name}:${azurerm_virtual_network.azure-spoke-island-r1.guid}"
  gw_subnet        = azurerm_subnet.r1-azure-spoke-island-gw-subnet.address_prefixes[0]
  use_existing_vpc = true
  attached         = false
  region           = var.azr_r1_location
  account          = var.azr_account
  single_ip_snat   = true
  single_az_ha     = false
  ha_gw            = false
  resource_group   = azurerm_resource_group.azr-r1-spoke-island-rg.name
  depends_on       = [azurerm_route_table.r1-azure-spoke-island-vm-subnet-rt, azurerm_route_table.r1-azure-spoke-island-vm-subnet-2-rt]
}

resource "aviatrix_gateway_dnat" "test_dnat" {
  gw_name = module.azr_r1_spoke_island.spoke_gateway.gw_name
  dnat_policy {
    src_cidr    = "0.0.0.0/0"
    dst_cidr    = "${module.azr_r1_spoke_island.spoke_gateway.private_ip}/32"
    dst_port    = "80"
    protocol    = "tcp"
    interface   = "eth0"
    connection  = "None"
    dnat_ips    = azurerm_container_group.island_container_group.ip_address
    dnat_port   = "8080"
    exclude_rtb = ""
  }
}

resource "azurerm_network_security_rule" "inbound-http" {
  access                      = "Allow"
  direction                   = "Inbound"
  name                        = "allow-http-in"
  network_security_group_name = "av-sg-${module.azr_r1_spoke_island.spoke_gateway.gw_name}"
  priority                    = 1500
  protocol                    = "Tcp"
  destination_port_range      = "80"
  destination_address_prefix  = "*"
  source_port_range           = "*"
  source_address_prefix       = "*"
  resource_group_name         = azurerm_resource_group.azr-r1-spoke-island-rg.name
}
