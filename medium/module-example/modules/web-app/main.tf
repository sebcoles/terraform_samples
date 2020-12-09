resource "azurerm_app_service" "app" {
  name                = var.app_name
  resource_group_name = var.resource_group_name
  location            = var.location
  app_service_plan_id = var.app_service_plan_id
  enabled             = true
  https_only          = true

  site_config {
    dotnet_framework_version = "v5.0"
  }

  identity {
    type = "SystemAssigned"
  }
}