output "connection_string" {
  value = azurerm_cosmosdb_account.cosmos.connection_strings[0]
}