data "azurerm_subscription" "current" {
}

output "current_subscription_display_name" {
  value = data.azurerm_subscription.current.display_name
}

data "azurerm_resource_group" "rg" {
  name = var.resource_group
}

output "rg_id" {
  value = data.azurerm_resource_group.rg.id
}

data "azurerm_resources" "res" {
  resource_group_name = var.resource_group
}

output "rg_resources" {
  value = data.azurerm_resources.res
}
