locals {
  resource_group_name = var.resource_group_name
  app_name            = var.app_name
  location            = var.location
  key_vault_id        = var.key_vault_id
}

resource "azurerm_cosmosdb_account" "cosmos" {
  name                = local.app_name
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
  name                = local.app_name
  resource_group_name = azurerm_cosmosdb_account.cosmos.resource_group_name
  account_name        = azurerm_cosmosdb_account.cosmos.name
}

resource "azurerm_cosmosdb_mongo_collection" "table" {
  name                = local.app_name
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
  key_vault_id = local.key_vault_id
}