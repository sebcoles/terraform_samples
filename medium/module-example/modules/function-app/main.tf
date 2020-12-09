resource "azurerm_function_app" "fa" {
  name                       = var.function_name
  resource_group_name        = var.resource_group_name
  location                   = var.location
  app_service_plan_id        = var.app_service_plan_id
  storage_account_name       = var.storage_account_name
  storage_account_access_key = var.storage_account_access_key
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