#########################################################
# Variables
#########################################################
locals {
  project_name        = var.project_name
  resource_group_name = var.resource_group_name
  location            = var.location
}

data "azurerm_client_config" "current" {}

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
  name                            = "${local.project_name}-kv"
  location                        = local.location
  resource_group_name             = azurerm_resource_group.rg.name
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  sku_name                        = "standard"
  enabled_for_deployment          = false
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = false
}

resource "azurerm_key_vault_access_policy" "sp" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

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
  name                = "${local.project_name}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "http"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "https"
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
resource "azurerm_cosmosdb_account" "cosmos" {
  name                = "${local.project_name}-cosmos"
  resource_group_name = local.resource_group_name
  location            = local.location
  offer_type          = "Standard"
  kind                = "MongoDB"

  enable_automatic_failover = false

  consistency_policy {
    consistency_level = "Strong"
  }

  geo_location {
    location          = local.location
    failover_priority = 0
  }

  capabilities {
    name = "EnableMongo"
  }
}

resource "azurerm_cosmosdb_mongo_database" "mongodb" {
  name                = "${local.project_name}-cosmos"
  resource_group_name = azurerm_cosmosdb_account.cosmos.resource_group_name
  account_name        = azurerm_cosmosdb_account.cosmos.name
}

resource "azurerm_cosmosdb_mongo_collection" "table" {
  name                = "${local.project_name}-cosmos"
  resource_group_name = azurerm_cosmosdb_mongo_database.mongodb.resource_group_name
  account_name        = azurerm_cosmosdb_mongo_database.mongodb.account_name
  database_name       = azurerm_cosmosdb_mongo_database.mongodb.name
  shard_key           = "_shardKey"
  throughput          = 400

  index { keys = ["_id"] }
}

resource "azurerm_key_vault_secret" "cosmos_conn" {
  name         = "cosmos-conn"
  value        = "${azurerm_cosmosdb_account.cosmos.connection_strings[0]}&retryWrites=false"
  key_vault_id = azurerm_key_vault.kv.id
}

#########################################################
# FUNCTIONS
#########################################################
resource "azurerm_app_service_plan" "service_plan" {
  name                         = "${local.project_name}-plan"
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
  ip_restriction_subnet_id   = azurerm_subnet.apim_snet.id

  extra_app_settings = {
  }
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
  ip_restriction_subnet_id   = azurerm_subnet.subnet.id
  
  extra_app_settings = {
    mongo_connection_string = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.cosmos_conn.id})"
  }
}
