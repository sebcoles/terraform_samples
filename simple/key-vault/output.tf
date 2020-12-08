output "vault_uri" {
  value = ["${azurerm_key_vault.simple_key_vault.vault_uri}"]
}