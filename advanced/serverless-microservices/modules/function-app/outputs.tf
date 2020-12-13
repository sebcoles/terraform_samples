output "host_key" {
  value = data.external.fa_host_key
}

output "default_hostname" {
  value = azurerm_function_app.fa.default_hostname
}