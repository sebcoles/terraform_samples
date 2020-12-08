resource "random_id" "storage_account_name" {
  byte_length = 8
}

resource "azurerm_resource_group" "resource_group" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_storage_account" "sa" {
  name                     = random_id.storage_account_name.hex
  resource_group_name      = azurerm_resource_group.resource_group.name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
}

resource "azurerm_app_service_plan" "example_function" {
  name                         = var.function_name
  resource_group_name          = azurerm_resource_group.resource_group.name
  location                     = var.location
  kind                         = "elastic"
  maximum_elastic_worker_count = 30

  sku {
    tier = "ElasticPremium"
    size = "EP1"
  }
}

resource "azurerm_function_app" "fa" {
  name                       = var.function_name
  resource_group_name        = azurerm_resource_group.resource_group.name
  location                   = var.location
  app_service_plan_id        = azurerm_app_service_plan.example_function.id
  storage_account_name       = azurerm_storage_account.sa.name
  storage_account_access_key = azurerm_storage_account.sa.primary_access_key
  enabled                    = true
  https_only                 = true
  version                    = "~3"

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME     = "node"
    WEBSITE_NODE_DEFAULT_VERSION = "~12"
    WEBSITE_RUN_FROM_PACKAGE     = "1"
    FUNCTION_APP_EDIT_MODE       = "readonly"
  }

  identity {
    type = "SystemAssigned"
  }
}