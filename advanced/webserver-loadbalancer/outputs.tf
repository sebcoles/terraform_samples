output "lb_ipaddress" {
  value = [azurerm_public_ip.public_ip.ip_address]
}