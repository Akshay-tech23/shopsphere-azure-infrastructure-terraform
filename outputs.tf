output "resource_group_name" {
  description = "ShopSphere application resource group name."
  value       = azurerm_resource_group.shopsphere.name
}

output "virtual_network_name" {
  description = "ShopSphere virtual network name."
  value       = azurerm_virtual_network.shopsphere.name
}

output "frontend_subnet_id" {
  description = "Resource ID of the frontend subnet."
  value       = azurerm_subnet.frontend.id
}

output "backend_subnet_id" {
  description = "Resource ID of the backend subnet."
  value       = azurerm_subnet.backend.id
}

output "backend_private_ip" {
  description = "Private IP address assigned to the backend network interface."
  value       = azurerm_network_interface.backend.private_ip_address
}

output "backend_vm_id" {
  description = "Resource ID of the backend Linux virtual machine."
  value       = azurerm_linux_virtual_machine.backend.id
}
