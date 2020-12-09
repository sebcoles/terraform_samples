resource "azurerm_resource_group" "resource_group" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_app_service_plan" "example_app" {
  name                = var.app_name
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = var.location

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_app_service" "app_service" {
  name                = var.app_name
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = var.location
  app_service_plan_id = azurerm_app_service_plan.example_app.id
  enabled             = true
  https_only          = true

  app_settings = {
    JAM = "Jam"
  }

  site_config {
    dotnet_framework_version = "v5.0"
  }

  identity {
    type = "SystemAssigned"
  }
}