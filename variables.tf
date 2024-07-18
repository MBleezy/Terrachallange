variable "resource_group_location" {
  default     = "eastus"
  description = "Location of the resource group."
}

variable "resource_group_name" {
  default     = "mbleezarde-sandbox"
  description = "Name of the resource group."
}

variable "prefix" {
  type        = string
  default     = "Terra-Chal-"
  description = "Prefix of the resource name"
}

variable "username" {
  type        = string
  description = "The username for the local account that will be created on the new VM."
  default     = "azureadmin"
}



variable "vault_name" {
  description = "The name of the Recovery Services Vault"
  type        = string
  default     = "myrsv-02"
}

variable "location" {
  description = "The location of the Recovery Services Vault"
  type        = string
  default     = "East US"
}

variable "vault_sku" {
  description = "The SKU of the Recovery Services Vault. Possible values are Standard and Premium."
  type        = string
  default     = "Standard"
}

variable "private_endpoint_name" {
  description = "The name of the private endpoint"
  type        = string
  default     = "private-endpoint"
}

variable "storage_mode_type" {
  description = "The storage type of the Recovery Services Vault."
  type        = string
  default     = "ZoneRedundant"
}

variable "vm_backup_policy_name" {
  type = string
  default = "terra_chal_backup_policy"
}

variable "vm_backup_policy_frequency" {
  type = string
  default = "Daily"
}

variable "vm_backup_policy_time"{
  type = string
  default = "23:00"
}

