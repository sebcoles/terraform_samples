module "resource_group" {
  source              = "./modules/resource-group"
  resource_group_name = var.resource_group_name
  location            = var.location
}

module "function_service_plan" {
  source              = "./modules/service-plan"
  plan_name           = "function-service-plan"
  resource_group_name = module.resource_group.name
  location            = var.location
  sku_tier            = "ElasticPremium"
  sku_size            = "EP1"
}

module "web_app_service_plan" {
  source              = "./modules/service-plan"
  plan_name           = "web-app-service-plan"
  resource_group_name = module.resource_group.name
  location            = var.location
  sku_tier            = "Standard"
  sku_size            = "S1"
}

module "web_app" {
  source              = "./modules/web-app"
  count               = 3
  app_name            = "${var.web_app_name}-${count.index + 1}"
  resource_group_name = module.resource_group.name
  location            = var.location
  app_service_plan_id = module.web_app_service_plan.id
}

module "storage_account" {
  source              = "./modules/storage-account"
  resource_group_name = module.resource_group.name
  location            = var.location
}

module "function" {
  source                     = "./modules/function-app"
  function_name              = var.function_name
  resource_group_name        = module.resource_group.name
  location                   = var.location
  app_service_plan_id        = module.function_service_plan.id
  storage_account_name       = module.storage_account.name
  storage_account_access_key = module.storage_account.primary_access_key
}