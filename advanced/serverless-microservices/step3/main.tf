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
  name                            = "${local.project_name}-kv"
  location                        = local.location
  resource_group_name             = azurerm_resource_group.rg.name
  tenant_id                       = local.tenant_id
  sku_name                        = "standard"
  enabled_for_deployment          = false
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = false
}

#########################################################
# APIM
#########################################################
data "external" "fa_host_key" {
  program = ["bash", "-c", "az rest --method post --uri /subscriptions/${local.subscription_id}/resourceGroups/${local.resource_group_name}/providers/Microsoft.Web/sites/${local.function_name}/host/default/listKeys?api-version=2019-08-01 --query functionKeys"]

  depends_on = [
    azurerm_function_app.fa
  ]
}

resource "azurerm_key_vault_secret" "fa_host_key" {
  name         = "fa-${azurerm_function_app.fa.name}-host-key"
  value        = data.external.fa_host_key.result.default
  key_vault_id = local.key_vault_id
}

data "external" "fa_host_key" {
  program = ["bash", "-c", "az rest --method post --uri /subscriptions/${local.subscription_id}/resourceGroups/${local.resource_group_name}/providers/Microsoft.Web/sites/${local.function_name}/host/default/listKeys?api-version=2019-08-01 --query functionKeys"]

  depends_on = [
    azurerm_function_app.fa
  ]
}

resource "azurerm_key_vault_secret" "fa_host_key" {
  name         = "fa-${azurerm_function_app.fa.name}-host-key"
  value        = data.external.fa_host_key.result.default
  key_vault_id = local.key_vault_id
}

#########################################################
# APIM
#########################################################
resource "azurerm_api_management" "apim" {
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
}




