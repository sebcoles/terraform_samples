resource "random_id" "storage_account_name" {
  keepers = {
    resource_group = var.resource_group_name
  }

  byte_length = 8
}

resource "azurerm_resource_group" "resource_group" {
  name     = random_id.storage_account_name.keepers.resource_group
  location = var.resource_group_location
}

resource "azurerm_storage_account" "storage_account1" {
  name                     = random_id.storage_account_name.hex
  resource_group_name      = azurerm_resource_group.resource_group.name
  location                 = var.resource_group_location
  account_tier             = var.config["account_tier"]
  account_replication_type = var.config["account_replication_type"]
}

resource "azurerm_storage_container" "storage_container1" {
  name                  = "vhds"
  storage_account_name  = azurerm_storage_account.storage_account1.name
  container_access_type = "private"
}

resource "azurerm_public_ip" "public_ip1" {
  name                = var.config["public_ip_address_name"]
  location            = var.resource_group_location
  resource_group_name = azurerm_resource_group.resource_group.name
  allocation_method   = var.config["allocation_method"]
  domain_name_label   = var.dns_label_prefix
}

resource "azurerm_virtual_network" "virtual_network1" {
  name                = var.config["virtual_network_name"]
  address_space       = [var.config["address_space"]]
  location            = var.resource_group_location
  resource_group_name = azurerm_resource_group.resource_group.name
}

resource "azurerm_subnet" "subnet1" {
  name                 = var.config["subnet_name"]
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.virtual_network1.name
  address_prefixes     = var.prefixes["address_prefixes"]
}

resource "azurerm_network_interface" "network_interface1" {
  name                = var.config["nic_name"]
  location            = var.resource_group_location
  resource_group_name = azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip1.id
  }
}

resource "azurerm_virtual_machine" "virtual_machine1" {
  name                  = var.config["vm_name"]
  location              = var.resource_group_location
  resource_group_name   = azurerm_resource_group.resource_group.name
  network_interface_ids = [azurerm_network_interface.network_interface1.id]
  vm_size               = var.config["vm_size"]

  os_profile {
    computer_name  = var.config["vm_name"]
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  storage_image_reference {
    publisher = var.config["image_publisher"]
    offer     = var.config["image_offer"]
    sku       = lookup(var.ubuntu_os_version_map, var.ubuntu_os_version)
    version   = "latest"
  }

  storage_os_disk {
    name          = "osdisk1"
    vhd_uri       = "${azurerm_storage_account.storage_account1.primary_blob_endpoint}${azurerm_storage_container.storage_container1.name}/osdisk1.vhd"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  storage_data_disk {
    name          = "datadisk0"
    vhd_uri       = "${azurerm_storage_account.storage_account1.primary_blob_endpoint}${azurerm_storage_container.storage_container1.name}/datadisk0.vhd"
    disk_size_gb  = "1023"
    create_option = "Empty"
    lun           = 0
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = var.admin_sshkey
    }
  }

  boot_diagnostics {
    enabled     = "true"
    storage_uri = azurerm_storage_account.storage_account1.primary_blob_endpoint
  }
}
