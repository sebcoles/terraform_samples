#########################################################
# Variables
#########################################################
locals {
  project_name        = var.project_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tenant_id           = var.tenant_id
  prinicipal_id       = var.prinicipal_id
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  subscription_id     = var.subscription_id
}


#########################################################
# Resource Group
#########################################################
resource "azurerm_resource_group" "rg" {
  name     = local.resource_group_name
  location = local.location
}

#########################################################
# KEY VAULT
#########################################################
resource "azurerm_key_vault" "kv" {
  name                            = local.project_name
  location                        = local.location
  resource_group_name             = azurerm_resource_group.rg.name
  tenant_id                       = local.tenant_id
  sku_name                        = "standard"
  enabled_for_deployment          = false
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = false
}

resource "azurerm_key_vault_access_policy" "sp" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = local.tenant_id
  object_id    = local.prinicipal_id

  secret_permissions = [
    "delete",
    "get",
    "set",
    "list"
  ]
}


#########################################################
# NETWORKS
#########################################################
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

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

  security_rule {
    name                       = "http"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_virtual_network" "virtual_network" {
  name                = "MyVNET"
  address_space       = ["10.0.0.0/16"]
  location            = local.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "MySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.virtual_network.name
  address_prefixes     = ["10.0.0.0/27"]

    delegation {
    name = "fadelegation"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }

  service_endpoints = ["Microsoft.Web"]
}

resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

#########################################################
# COSMOS DB
#########################################################
module "cosmos_db" {
  source              = "./modules/cosmos-db"
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.location
  app_name            = local.project_name
  key_vault_id        = azurerm_key_vault.kv.id

  depends_on = [
    azurerm_key_vault_access_policy.sp
  ]
}

#########################################################
# FUNCTIONS
#########################################################
resource "azurerm_app_service_plan" "service_plan" {
  name                         = local.project_name
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = local.location
  kind                         = "elastic"
  maximum_elastic_worker_count = 30
  sku {
    tier = "ElasticPremium"
    size = "EP1"
  }
}

resource "random_id" "storage_account_name" {
  byte_length = 8
}

resource "azurerm_storage_account" "sa" {
  name                     = random_id.storage_account_name.hex
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = local.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

module "function_date" {
  source                     = "./modules/function-app"
  location                   = local.location
  resource_group_name        = azurerm_resource_group.rg.name
  function_name              = "date${random_id.storage_account_name.hex}"
  app_service_plan_id        = azurerm_app_service_plan.service_plan.id
  storage_account_name       = azurerm_storage_account.sa.name
  storage_account_access_key = azurerm_storage_account.sa.primary_access_key
  key_vault_id               = azurerm_key_vault.kv.id
  subnet_id                  = azurerm_subnet.subnet.id
  subscription_id            = local.subscription_id
  ip_restriction_subnet_id         = azurerm_subnet.subnet.id
}

module "function_cosmos_data" {
  source                     = "./modules/function-app"
  location                   = local.location
  resource_group_name        = azurerm_resource_group.rg.name
  function_name              = "cosmos${random_id.storage_account_name.hex}"
  app_service_plan_id        = azurerm_app_service_plan.service_plan.id
  storage_account_name       = azurerm_storage_account.sa.name
  storage_account_access_key = azurerm_storage_account.sa.primary_access_key
  key_vault_id               = azurerm_key_vault.kv.id
  subnet_id                  = azurerm_subnet.subnet.id
  subscription_id            = local.subscription_id
  ip_restriction_subnet_id         = azurerm_subnet.subnet.id
}

#########################################################
# APIM
#########################################################
/* resource "azurerm_api_management" "apim" {
  name                 = local.project_name
  resource_group_name  = azurerm_resource_group.rg.name
  location             = local.location
  publisher_name       = local.publisher_name
  publisher_email      = local.publisher_email
  virtual_network_type = "External"

  sku_name = "Developer_1"

  virtual_network_configuration {
    subnet_id = azurerm_subnet.subnet.id
  }

  identity {
    type = "SystemAssigned"
  }
}

module "apim_api_date" {
  source              = "./modules/apim-api"
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.location
  api_name            = "date"
  api_management_name = "date"
  default_hostname    = module.function_date.default_hostname
  host_key            = module.function_date.host_key
  key_vault_id        = azurerm_key_vault.kv.id
}

module "apim_api_cosmos" {
  source              = "./modules/apim-api"
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.location
  api_name            = "cosmos"
  api_management_name = "cosmos"
  default_hostname    = module.function_cosmos_data.default_hostname
  host_key            = module.function_cosmos_data.host_key
  key_vault_id        = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_access_policy" "apim" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = azurerm_api_management.apim.identity[0].tenant_id
  object_id    = azurerm_api_management.apim.identity[0].principal_id

  secret_permissions = [
    "Get"
  ]
} */




