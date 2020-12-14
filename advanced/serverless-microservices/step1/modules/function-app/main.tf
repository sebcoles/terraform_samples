locals {
  function_name              = var.function_name
  resource_group_name        = var.resource_group_name
  location                   = var.location
  app_service_plan_id        = var.app_service_plan_id
  storage_account_name       = var.storage_account_name
  storage_account_access_key = var.storage_account_access_key
  key_vault_id               = var.key_vault_id
  subnet_id                  = var.subnet_id
  subscription_id            = var.subscription_id
  ip_restriction_subnet_id   = var.ip_restriction_subnet_id
  extra_app_settings         = var.extra_app_settings
}

resource "azurerm_function_app" "fa" {
  name                       = local.function_name
  resource_group_name        = local.resource_group_name
  location                   = local.location
  app_service_plan_id        = local.app_service_plan_id
  storage_account_name       = local.storage_account_name
  storage_account_access_key = local.storage_account_access_key
  enabled                    = true
  https_only                 = true
  version                    = "~3"

  app_settings = merge(
    {
      FUNCTIONS_WORKER_RUNTIME     = "node"
      WEBSITE_NODE_DEFAULT_VERSION = "~12"
      WEBSITE_RUN_FROM_PACKAGE     = "1"
      FUNCTION_APP_EDIT_MODE       = "readonly"
    },
    local.extra_app_settings
  )

  site_config {
    ftps_state = "Disabled"
    ip_restriction {
      virtual_network_subnet_id = var.ip_restriction_subnet_id
    }
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_key_vault_access_policy" "fa" {
  key_vault_id = local.key_vault_id
  tenant_id    = azurerm_function_app.fa.identity[0].tenant_id
  object_id    = azurerm_function_app.fa.identity[0].principal_id

  secret_permissions = [
    "Get"
  ]
}

resource "azurerm_app_service_virtual_network_swift_connection" "vnet_int" {
  app_service_id = azurerm_function_app.fa.id
  subnet_id      = local.subnet_id
}


