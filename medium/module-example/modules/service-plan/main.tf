resource "azurerm_app_service_plan" "service_plan" {
  name                         = var.plan_name
  resource_group_name          = var.resource_group_name
  location                     = var.location

  sku {
    tier = var.sku_tier
    size = var.sku_size
  }
}
