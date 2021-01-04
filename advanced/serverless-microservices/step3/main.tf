#########################################################
# Variables
#########################################################
locals {
  project_name            = var.project_name
  resource_group_name     = var.resource_group_name
  location                = var.location
  subscription_id         = var.subscription_id
  date_function_name      = var.date_function_name
  date_default_hostname   = var.date_default_hostname
  cosmos_function_name    = var.cosmos_function_name
  cosmos_default_hostname = var.cosmos_default_hostname
}

#########################################################
# Key Vault & Host Keys
#########################################################
data "azurerm_key_vault" "kv" {
  name                = "${local.project_name}-kv"
  resource_group_name = local.resource_group_name
}

module "apim_api_date" {
  source              = "./modules/apim-api"
  resource_group_name = local.resource_group_name
  location            = local.location
  default_hostname    = local.date_default_hostname
  key_vault_id        = data.azurerm_key_vault.kv.id
  subscription_id     = local.subscription_id
  function_name       = local.date_function_name
}

module "apim_api_cosmos" {
  source              = "./modules/apim-api"
  resource_group_name = local.resource_group_name
  location            = local.location
  default_hostname    = local.cosmos_default_hostname
  key_vault_id        = data.azurerm_key_vault.kv.id
  subscription_id     = local.subscription_id
  function_name       = local.date_function_name
}




