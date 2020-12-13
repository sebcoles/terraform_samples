#########################################################
# Resource Group
#########################################################
resource "azurerm_resource_group" "resource_group" {
  name     = var.resource_group_name
  location = var.location
}

#########################################################
# NETWORKS
#########################################################
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  security_rule {
    name                       = "http"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_virtual_network" "virtual_network" {
  name                = "MyVNET"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.resource_group.name
}

resource "azurerm_subnet" "bastionsubnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.virtual_network.name
  address_prefixes     = ["10.0.1.0/27"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "MySubnet"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.virtual_network.name
  address_prefixes     = ["10.0.0.0/27"]
}

resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

#########################################################
# BASTION HOST
#########################################################
resource "azurerm_public_ip" "bastion_ip" {
  name                = "BastionIP"
  location            = var.location
  resource_group_name = azurerm_resource_group.resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion" {
  name                = "bastion"
  location            = var.location
  resource_group_name = azurerm_resource_group.resource_group.name

  ip_configuration {
    name                 = "bastion-configuration"
    subnet_id            = azurerm_subnet.bastionsubnet.id
    public_ip_address_id = azurerm_public_ip.bastion_ip.id
  }
}

#########################################################
# AVAILABILITY SET
#########################################################
resource "azurerm_availability_set" "aset" {
  name                         = "example-aset"
  location                     = var.location
  resource_group_name          = azurerm_resource_group.resource_group.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
}

#########################################################
# LOAD BALANCER
#########################################################
resource "azurerm_public_ip" "public_ip" {
  name                = "myPublicIP"
  location            = var.location
  resource_group_name = azurerm_resource_group.resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "lb" {
  name                = "lb"
  location            = var.location
  resource_group_name = azurerm_resource_group.resource_group.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_lb_backend_address_pool" "lb_backend" {
  resource_group_name = azurerm_resource_group.resource_group.name
  loadbalancer_id     = azurerm_lb.lb.id
  name                = "BackEndAddressPool"
}

resource "azurerm_lb_probe" "probe" {
  resource_group_name = azurerm_resource_group.resource_group.name
  loadbalancer_id     = azurerm_lb.lb.id
  name                = "httpProbe"
  port                = 80
  protocol            = "http"
  interval_in_seconds = 15
  request_path        = "/"
}

resource "azurerm_lb_rule" "lb_rule" {
  resource_group_name            = azurerm_resource_group.resource_group.name
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "LBRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  probe_id                       = azurerm_lb_probe.probe.id
  enable_tcp_reset               = true
  backend_address_pool_id        = azurerm_lb_backend_address_pool.lb_backend.id
}

#########################################################
# WEB SERVERS
#########################################################
module "web_servers" {
  source                  = "./modules/webserver"
  count                   = 2
  resource_group_name     = azurerm_resource_group.resource_group.name
  location                = var.location
  admin_username          = var.admin_username
  admin_password          = var.admin_password
  azurerm_subnet_id       = azurerm_subnet.subnet.id
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb_backend.id
  availability_set_id     = azurerm_availability_set.aset.id
}


