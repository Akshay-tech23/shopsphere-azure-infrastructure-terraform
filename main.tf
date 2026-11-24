terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  # Keep environment-specific backend values in the ignored backend.hcl file.
  # See backend.hcl.example and the README before running terraform init.
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "shopsphere" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "shopsphere" {
  name                = "vnet-shopsphere-dev"
  location            = azurerm_resource_group.shopsphere.location
  resource_group_name = azurerm_resource_group.shopsphere.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "frontend" {
  name                 = "snet-frontend"
  resource_group_name  = azurerm_resource_group.shopsphere.name
  virtual_network_name = azurerm_virtual_network.shopsphere.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "backend" {
  name                 = "snet-backend"
  resource_group_name  = azurerm_resource_group.shopsphere.name
  virtual_network_name = azurerm_virtual_network.shopsphere.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "frontend" {
  name                = "nsg-frontend"
  location            = azurerm_resource_group.shopsphere.location
  resource_group_name = azurerm_resource_group.shopsphere.name

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTPS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "backend" {
  name                = "nsg-backend"
  location            = azurerm_resource_group.shopsphere.location
  resource_group_name = azurerm_resource_group.shopsphere.name

  security_rule {
    name                       = "Allow-Frontend-API"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "frontend" {
  subnet_id                 = azurerm_subnet.frontend.id
  network_security_group_id = azurerm_network_security_group.frontend.id
}

resource "azurerm_subnet_network_security_group_association" "backend" {
  subnet_id                 = azurerm_subnet.backend.id
  network_security_group_id = azurerm_network_security_group.backend.id
}

resource "azurerm_network_interface" "backend" {
  name                = "nic-shopsphere-backend"
  location            = azurerm_resource_group.shopsphere.location
  resource_group_name = azurerm_resource_group.shopsphere.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.backend.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "backend" {
  name                = "vm-shopsphere-backend"
  resource_group_name = azurerm_resource_group.shopsphere.name
  location            = azurerm_resource_group.shopsphere.location
  size                = var.backend_vm_size

  admin_username                  = var.admin_username
  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.backend.id
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(pathexpand(var.admin_ssh_public_key_path))
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  # The NIC depends on the backend subnet; this explicit dependency also
  # ensures the subnet's NSG association is ready before VM provisioning.
  depends_on = [
    azurerm_subnet_network_security_group_association.backend
  ]
}
