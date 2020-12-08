resource "azurerm_resource_group" "simple_key_vault_rg" {
  name     = var.resource_group.name
  location = var.resource_group.location

  tags = {
    Source = "Simple Key-Vault"
  }
}

resource "azurerm_key_vault" "simple_key_vault" {
  name                = var.keyvault.name
  location            = azurerm_resource_group.simple_key_vault_rg.location
  resource_group_name = azurerm_resource_group.simple_key_vault_rg.name
  tenant_id           = var.keyvault.tenant_id
  sku_name            = var.keyvault.sku_name
  access_policy {
    tenant_id = var.keyvault.tenant_id
    object_id = var.keyvault.object_id

    key_permissions    = var.keyvault.keys_permissions
    secret_permissions = var.keyvault.secrets_permissions
  }

  enabled_for_deployment          = var.keyvault.enabled_for_deployment
  enabled_for_disk_encryption     = var.keyvault.enabled_for_disk_encryption
  enabled_for_template_deployment = var.keyvault.enabled_for_template_deployment
}