output "function_name" {
  value = azurerm_function_app.fa.name
}

output "default_hostname" {
  value = azurerm_function_app.fa.default_hostname
}