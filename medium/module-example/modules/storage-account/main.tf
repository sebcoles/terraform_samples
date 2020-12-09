resource "random_id" "storage_account_name" {
  byte_length = 8
}

resource "azurerm_storage_account" "sa" {
  name                     = random_id.storage_account_name.hex
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
}