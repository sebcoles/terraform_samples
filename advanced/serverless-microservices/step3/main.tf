#########################################################
# Variables
#########################################################
locals {
  project_name            = var.project_name
  resource_group_name     = var.resource_group_name
  location                = var.location
  publisher_name          = var.publisher_name
  publisher_email         = var.publisher_email
  subscription_id         = var.subscription_id
  date_function_name      = var.date_function_name
  date_default_hostname   = var.date_default_hostname
  cosmos_function_name    = var.cosmos_function_name
  cosmos_default_hostname = var.cosmos_default_hostname
}

#########################################################
# Key Vault & Host Keys
#########################################################
data "azurerm_subnet" "apim_snet" {
  name                 = "${local.project_name}-apim-snet"
  resource_group_name  = local.resource_group_name
  virtual_network_name = "MyVNET"
}

#########################################################
# Key Vault & Host Keys
#########################################################
data "azurerm_key_vault" "kv" {
  name                = "${local.project_name}-kv"
  resource_group_name = local.resource_group_name
}

#########################################################
# APIM
#########################################################
resource "azurerm_api_management" "apim" {
  name                 = "${local.project_name}215f9"
  resource_group_name  = local.resource_group_name
  location             = local.location
  publisher_name       = local.publisher_name
  publisher_email      = local.publisher_email
  virtual_network_type = "External"

  sku_name = "Developer_1"

  virtual_network_configuration {
    subnet_id = data.azurerm_subnet.apim_snet.id
  }

  identity {
    type = "SystemAssigned"
  }
}

module "apim_api_date" {
  source              = "./modules/apim-api"
  resource_group_name = local.resource_group_name
  location            = local.location
  api_management_name = azurerm_api_management.apim.name
  default_hostname    = local.date_default_hostname
  key_vault_id        = data.azurerm_key_vault.kv.id
  subscription_id     = local.subscription_id
  function_name       = local.date_function_name

  depends_on = [ 
    azurerm_api_management.apim
   ]
}

/* module "apim_api_cosmos" {
  source              = "./modules/apim-api"
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.location
  api_management_name = "cosmos"
  default_hostname    = local.cosmos_default_hostname
  key_vault_id        = data.azurerm_key_vault.kv.id
    subscription_id     = local.subscription_id
  function_name       = local.date_function_name

    depends_on = [ 
    azurerm_api_management.apim
   ]
} */

resource "azurerm_key_vault_access_policy" "apim" {
  key_vault_id = data.azurerm_key_vault.kv.id
  tenant_id    = azurerm_api_management.apim.identity[0].tenant_id
  object_id    = azurerm_api_management.apim.identity[0].principal_id

  secret_permissions = [
    "Get"
  ]
}




