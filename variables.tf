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
  type    = string
  default = "terra_chal_backup_policy"
}

variable "vm_backup_policy_frequency" {
  type    = string
  default = "Daily"
}

variable "vm_backup_policy_time" {
  type    = string
  default = "23:00"
}

variable "key_vault_name" {
  type        = string
  description = "The name of the key vault to be created. The value will be randomly generated if blank."
  default     = ""
}

variable "key_name" {
  type        = string
  description = "The name of the key to be created. The value will be randomly generated if blank."
  default     = ""
}

variable "sku_name" {
  type        = string
  description = "The SKU of the vault to be created."
  default     = "standard"
  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "The sku_name must be one of the following: standard, premium."
  }
}

variable "key_permissions" {
  type        = list(string)
  description = "List of key permissions."
  default     = ["List", "Create", "Delete", "Get", "Purge", "Recover", "Update", "GetRotationPolicy", "SetRotationPolicy"]
}

variable "secret_permissions" {
  type        = list(string)
  description = "List of secret permissions."
  default     = ["Get", "Set"]
}

variable "key_type" {
  description = "The JsonWebKeyType of the key to be created."
  default     = "RSA"
  type        = string
  validation {
    condition     = contains(["EC", "EC-HSM", "RSA", "RSA-HSM"], var.key_type)
    error_message = "The key_type must be one of the following: EC, EC-HSM, RSA, RSA-HSM."
  }
}

variable "key_ops" {
  type        = list(string)
  description = "The permitted JSON web key operations of the key to be created."
  default     = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]
}

variable "key_size" {
  type        = number
  description = "The size in bits of the key to be created."
  default     = 2048
}

variable "msi_id" {
  type        = string
  description = "The Managed Service Identity ID. If this value isn't null (the default), 'data.azurerm_client_config.current.object_id' will be set to this value."
  default     = null
}

variable "linux_secret" {
  type        = string
  description = "name for admin password object for linux vm to be stored as key vault secret"
  default     = "linux-admin-pw"
}

variable "windows_secret" {
  type        = string
  description = "name for admin password object for windows vm to be stored as key vault secret"
  default     = "windows-admin-pw"
}