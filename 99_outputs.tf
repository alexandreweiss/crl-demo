output "ssh_azr_r1_app1" {
  value = module.azr_r1_app1_vm.vm_private_ip
}

output "ssh_azr_r1_app2" {
  value = module.azr_r1_app2_vm.vm_private_ip
}

output "ssh_azr_r2_app1" {
  value = module.azr_r2_app1_vm.vm_private_ip
}

output "ssh_azr_r2_app2" {
  value = module.azr_r2_app2_vm.vm_private_ip
}

output "ssh_azr_r1_app1_spoke_a" {
  value = var.azr_r1_spoke_app1_nata_advertised_ip
}

output "ssh_azr_r1_app1_spoke_b" {
  value = var.azr_r1_spoke_app1_natb_advertised_ip
}

output "ssh_aws_r1_app1" {
  value = module.aws_r1_app1_vm.private_ip
}

output "ssh_aws_r1_app2" {
  value = module.aws_r1_app2_vm.private_ip
}

output "ssh_aws_r2_app1" {
  value = module.aws_r2_app1_vm.private_ip
}

output "ssh_aws_r2_app2" {
  value = module.aws_r2_app2_vm.private_ip
}

output "azr_r1" {
  value = var.azr_r1_location
}

output "azr_r2" {
  value = var.azr_r2_location
}

output "guacamole_fqdn" {
  value = nonsensitive("https://${module.azr_r1_guacamole_vm.public_ip}/#/index.html?username=guacadmin&password=${var.vm_password}")
}

output "island_vnet_connectivity" {
  value = nonsensitive("http://${module.azr_r1_spoke_island.spoke_gateway.eip}")
}

# output "private_key" {
#   description = "Private key value"
#   value       = nonsensitive(module.key_pair_r1.private_key_pem)
# }
