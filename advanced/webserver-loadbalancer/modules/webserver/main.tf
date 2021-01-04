resource "random_id" "random" {
  byte_length = 8
}

resource "azurerm_network_interface" "network_interface" {
  name                = random_id.random.hex
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = random_id.random.hex
    subnet_id                     = var.azurerm_subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "virtual_machine" {
  name                  = random_id.random.hex
  location              = var.location
  resource_group_name   = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.network_interface.id]
  vm_size               = "Standard_F1"
  availability_set_id   = var.availability_set_id


  os_profile {
    computer_name  = substr(random_id.random.hex, 0, 10)
    admin_username = var.admin_username
    admin_password = var.admin_password

  }

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2012-R2-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name              = "osdisk1_${random_id.random.hex}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile_windows_config {
    provision_vm_agent = true

  }
}

resource "azurerm_network_interface_backend_address_pool_association" "assoc" {
  network_interface_id    = azurerm_network_interface.network_interface.id
  ip_configuration_name   = random_id.random.hex
  backend_address_pool_id = var.backend_address_pool_id
}