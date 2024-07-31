module "azr_r1_guacamole_vm" {
  source      = "github.com/alexandreweiss/misc-tf-modules/azr-linux-vm-pwd"
  environment = "Guacamole"
  tags = {
    "application" = "Guacamole"
  }
  location            = var.azr_r1_location
  location_short      = var.azr_r1_location_short
  index_number        = 01
  subnet_id           = module.azr_r1_spoke_app1.vpc.public_subnets[1].subnet_id
  resource_group_name = data.aviatrix_vpc.azr_r1_spoke_app1_vpc.resource_group
  customer_name       = var.customer_name
  admin_password      = var.vm_password
  # custom_data         = data.template_cloudinit_config.config.rendered
  custom_data      = base64encode(data.template_file.guacamole_config.rendered)
  enable_public_ip = true
  depends_on = [
  ]
}

# Add an inbound security rule on azr_r1_guacamole_vm to allow HTTPS traffic
resource "azurerm_network_security_rule" "guacamole_https" {
  name                        = "Allow-HTTPS"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = data.aviatrix_vpc.azr_r1_spoke_app1_vpc.resource_group
  network_security_group_name = module.azr_r1_guacamole_vm.nsg_name
}

data "template_file" "guacamole_config" {
  template = file("${path.module}/4_guacamole.tpl")

  vars = {
    hostname_r1_app1             = module.azr_r1_app1_vm.vm_private_ip
    hostname_r1_app2             = module.azr_r1_app2_vm.vm_private_ip
    hostname_r2_app1             = module.azr_r2_app1_vm.vm_private_ip
    hostname_r2_app2             = module.azr_r2_app2_vm.vm_private_ip
    hostname_aws_r1_app1         = module.aws_r1_app1_vm.private_ip
    hostname_aws_r1_app2         = module.aws_r1_app2_vm.private_ip
    hostname_aws_r2_app1         = module.aws_r1_app1_vm.private_ip
    hostname_aws_r2_app2         = module.aws_r1_app2_vm.private_ip
    hostname_r1_spoke_a_app1_nat = var.azr_r1_spoke_app1_nata_advertised_ip
    hostname_r1_spoke_b_app1_nat = var.azr_r1_spoke_app1_natb_advertised_ip
    azr_r1_location_short        = var.azr_r1_location_short
    azr_r2_location_short        = var.azr_r2_location_short
    aws_r1_location_short        = var.aws_r1_location_short
    aws_r2_location_short        = var.aws_r2_location_short
    application_1                = var.application_1
    application_2                = var.application_2
    vm_password                  = var.vm_password
    username                     = "admin-lab"
  }
}

