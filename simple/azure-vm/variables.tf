variable "resource_group_name" {
  description = "Name of the resource group container for all resources"
}

variable "resource_group_location" {
  description = "Azure region used for resource deployment"
}

variable "admin_username" {
  description = "User name for the Virtual Machine"
}

variable "admin_password" {
  description = "Password for the Virtual Machine."
}

variable "dns_label_prefix" {
  description = "Unique DNS Name for the Public IP used to access the Virtual Machine."
}

variable "ubuntu_os_version" {
  description = "The Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version."
}

variable "admin_sshkey" {
  description = "SSH key for authentication to the Virtual Machines"
}

#"The Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version."
variable "ubuntu_os_version_map" {
  type = map
  default = {
    "18.04-LTS" = "18.04-LTS"
  }
}

variable "config" {
  type = map
  default = {
    "image_publisher"          = "Canonical"
    "image_offer"              = "UbuntuServer"
    "nic_name"                 = "myVMNic"
    "subnet_name"              = "Subnet"
    "account_tier"             = "Standard"
    "public_ip_address_name"   = "myPublicIP"
    "allocation_method"        = "Dynamic"
    "vm_name"                  = "acctvm"
    "vm_size"                  = "Standard_F1"
    "virtual_network_name"     = "MyVNET"
    "account_replication_type" = "GRS"
    "address_space"            = "10.0.0.0/16"
  }
}

variable "prefixes" {
  type = map
  default = {
    "address_prefixes" = ["10.0.0.0/24"]
  }
}
