#IPAdress value only available with static IP Address
output "ipAddress" {
  value = [azurerm_public_ip.public_ip1.ip_address]
}