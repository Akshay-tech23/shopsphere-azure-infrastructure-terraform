variable "resource_group_name" {
  description = "Name of the ShopSphere application resource group."
  type        = string
  default     = "rg-shopsphere-dev"
}

variable "location" {
  description = "Azure region for ShopSphere infrastructure."
  type        = string
  default     = "Central India"
}

variable "backend_vm_size" {
  description = "Azure SKU for the backend Linux virtual machine."
  type        = string
  default     = "Standard_D2s_v3"
}

variable "admin_username" {
  description = "Linux administrator account created on the backend VM."
  type        = string
  default     = "azureuser"
}

variable "admin_ssh_public_key_path" {
  description = "Local path to the SSH public key. Never provide a private key."
  type        = string
  default     = "~/.ssh/shopsphere_azure.pub"
}
