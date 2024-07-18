output "public_ip_address" {
  value = azurerm_windows_virtual_machine.Terra_chal_win_vm.public_ip_address
}

output "admin_password" {
  sensitive = true
  value     = azurerm_windows_virtual_machine.Terra_chal_win_vm.admin_password
}

output "recovery_vault_id" {
  description = "The ID of the Recovery Services Vault."
  value       = azurerm_recovery_services_vault.terra_chal_vault.id
}

output "recovery_vault_name" {
  description = "The name of the Recovery Services Vault."
  value       = azurerm_recovery_services_vault.terra_chal_vault.name
}

output "backup_policy_ids" {
  description = "The IDs of the created Azure File Share backup policies."
  value       = { for policy in azurerm_backup_policy_file_share.terra_chal_backup_policy : policy.name => policy.id }
}