output "public_ip_address" {
  value = azurerm_windows_virtual_machine.Terra_chal_win_vm.public_ip_address
}

output "admin_password" {
  sensitive = true
  value     = azurerm_windows_virtual_machine.Terra_chal_win_vm.admin_password
}