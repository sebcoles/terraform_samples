locals {
  resource_group_name = var.resource_group_name
  location            = var.location
  default_hostname    = var.default_hostname
  key_vault_id        = var.key_vault_id
  subscription_id     = var.subscription_id
  function_name       = var.function_name
}

data "external" "fa_date_host_key" {
  program = ["bash", "-c", "az rest --method post --uri /subscriptions/${local.subscription_id}/resourceGroups/${local.resource_group_name}/providers/Microsoft.Web/sites/${local.function_name}/host/default/listKeys?api-version=2019-08-01 --query functionKeys"]
}

resource "azurerm_key_vault_secret" "fa_date_host_key" {
  name         = "${local.function_name}-host-key"
  value        = data.external.fa_date_host_key.result.default
  key_vault_id = local.key_vault_id
}

data "azurerm_key_vault_secret" "fa_date_host_key_data" {
  name         = azurerm_key_vault_secret.fa_date_host_key.name
  key_vault_id = azurerm_key_vault_secret.fa_date_host_key.key_vault_id
}