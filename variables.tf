variable "resource_group_location" {
  default     = "eastus"
  description = "Location of the resource group."
}

variable "resource_group_name" {
  default     = "mbleezarde-sandbox"
  description = "Name of the resource group."
}

variable "RGName" {
  type    = string
  default = "mbleezarde-sandbox"
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

variable "backup_policies" {
  type = map(object({
    name                   = string
    frequency              = string
    time                   = string
    retention_daily        = number
    retention_weekly       = number
    retention_monthly      = number
    retention_yearly       = number
    tags                   = map(string)
  }))
  description = "A map of backup policies to be created in the Recovery Services Vault."
  default = {
    default_policy = {
      name                   = "default_policy"
      frequency              = "Daily"
      time                   = "12:00"
      retention_daily        = 35
      retention_weekly       = 90
      retention_monthly      = 12
      retention_yearly       = 10
      tags                   = {}
    }
  }
}