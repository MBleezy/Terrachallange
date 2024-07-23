
data "azurerm_resource_group" "mbleezarde-sandbox" {
  name = "mbleezarde-sandbox"
}

# Create virtual network
resource "azurerm_virtual_network" "terra_chal_network" {
  name                = "${var.prefix}vnet"
  address_space       = ["10.0.0.0/16"]
  location            = data.azurerm_resource_group.mbleezarde-sandbox.location
  resource_group_name = data.azurerm_resource_group.mbleezarde-sandbox.name
}

# Create Web subnet
resource "azurerm_subnet" "terra_chal_Web_subnet" {
  name                 = "${var.prefix}Web-subnet"
  resource_group_name  = data.azurerm_resource_group.mbleezarde-sandbox.name
  virtual_network_name = azurerm_virtual_network.terra_chal_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create Data subnet
resource "azurerm_subnet" "terra_chal_Data_subnet" {
  name                 = "${var.prefix}Data-subnet"
  resource_group_name  = data.azurerm_resource_group.mbleezarde-sandbox.name
  virtual_network_name = azurerm_virtual_network.terra_chal_network.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Create Jumpbox subnet
resource "azurerm_subnet" "terra_chal_Jump_subnet" {
  name                 = "${var.prefix}Jumpbox-subnet"
  resource_group_name  = data.azurerm_resource_group.mbleezarde-sandbox.name
  virtual_network_name = azurerm_virtual_network.terra_chal_network.name
  address_prefixes     = ["10.0.3.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "terra_chal_pub_ip" {
  name                = "${var.prefix}public-ip"
  location            = data.azurerm_resource_group.mbleezarde-sandbox.location
  resource_group_name = data.azurerm_resource_group.mbleezarde-sandbox.name
  allocation_method   = "Dynamic"
}

resource "azurerm_public_ip" "terra_chal_Linux_pub_ip" {
  name                = "${var.prefix}linux-public-ip"
  location            = data.azurerm_resource_group.mbleezarde-sandbox.location
  resource_group_name = data.azurerm_resource_group.mbleezarde-sandbox.name
  allocation_method   = "Dynamic"
}

# Create Network Security Group and rules
resource "azurerm_network_security_group" "terra_chal_nsg" {
  name                = "${var.prefix}nsg"
  location            = data.azurerm_resource_group.mbleezarde-sandbox.location
  resource_group_name = data.azurerm_resource_group.mbleezarde-sandbox.name

  security_rule {
    name                       = "RDP"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "web"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "terra_chal_win_nic" {
  name                = "${var.prefix}nic"
  location            = data.azurerm_resource_group.mbleezarde-sandbox.location
  resource_group_name = data.azurerm_resource_group.mbleezarde-sandbox.name

  ip_configuration {
    name                          = "my_nic_configuration"
    subnet_id                     = azurerm_subnet.terra_chal_Web_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.terra_chal_pub_ip.id
  }
}

resource "azurerm_network_interface" "terra_chal_linux_nic" {
  name                = "${var.prefix}linux-nic"
  location            = data.azurerm_resource_group.mbleezarde-sandbox.location
  resource_group_name = data.azurerm_resource_group.mbleezarde-sandbox.name

  ip_configuration {
    name                          = "my_nic_configuration"
    subnet_id                     = azurerm_subnet.terra_chal_Data_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.terra_chal_Linux_pub_ip.id
  }
}


# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "Windows" {
  network_interface_id      = azurerm_network_interface.terra_chal_win_nic.id
  network_security_group_id = azurerm_network_security_group.terra_chal_nsg.id
}

resource "azurerm_network_interface_security_group_association" "Linux" {
  network_interface_id      = azurerm_network_interface.terra_chal_linux_nic.id
  network_security_group_id = azurerm_network_security_group.terra_chal_nsg.id
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "Terra_chal_SA" {
  name                     = "diag${random_id.random_id.hex}"
  location                 = data.azurerm_resource_group.mbleezarde-sandbox.location
  resource_group_name      = data.azurerm_resource_group.mbleezarde-sandbox.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

#Create Azure Key Vault
data "azurerm_client_config" "current" {}

resource "random_string" "azurerm_key_vault_name" {
  length  = 13
  lower   = true
  numeric = false
  special = false
  upper   = false
}

locals {
  current_user_id = coalesce(var.msi_id, data.azurerm_client_config.current.object_id)
}

resource "azurerm_key_vault" "vault" {
  name                       = coalesce(var.key_vault_name, "vault-${random_string.azurerm_key_vault_name.result}")
  location                   = var.resource_group_location
  resource_group_name        = data.azurerm_resource_group.mbleezarde-sandbox.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = var.sku_name
  soft_delete_retention_days = 7

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = local.current_user_id

    key_permissions    = var.key_permissions
    secret_permissions = var.secret_permissions
  }
}

resource "random_string" "azurerm_key_vault_key_name" {
  length  = 13
  lower   = true
  numeric = false
  special = false
  upper   = false
}

resource "azurerm_key_vault_key" "key" {
  name = coalesce(var.key_name, "key-${random_string.azurerm_key_vault_key_name.result}")

  key_vault_id = azurerm_key_vault.vault.id
  key_type     = var.key_type
  key_size     = var.key_size
  key_opts     = var.key_ops

  rotation_policy {
    automatic {
      time_before_expiry = "P30D"
    }

    expire_after         = "P90D"
    notify_before_expiry = "P29D"
  }
}

#Create secrets to be used as vm passwords and store in key vault
resource "random_password" "linux_vault_pw" {
  length           = 16
  special          = true
  override_special = "!#$%&,."
}

resource "random_password" "windows_vault_pw" {
  length           = 16
  special          = true
  override_special = "!#$%&,."
}

resource "azurerm_key_vault_secret" "linux_vm_secret" {
  key_vault_id = azurerm_key_vault.vault.id
  name         = var.linux_secret
  value        = random_password.linux_vault_pw.result
}

resource "azurerm_key_vault_secret" "windows_vm_secret" {
  key_vault_id = azurerm_key_vault.vault.id
  name         = var.windows_secret
  value        = random_password.windows_vault_pw.result
}

# Create virtual machine
resource "azurerm_windows_virtual_machine" "Terra_chal_win_vm" {
  name                  = "${var.prefix}vm"
  admin_username        = "azureuser"
  admin_password        = azurerm_key_vault_secret.windows_vm_secret.value
  location              = data.azurerm_resource_group.mbleezarde-sandbox.location
  resource_group_name   = data.azurerm_resource_group.mbleezarde-sandbox.name
  network_interface_ids = [azurerm_network_interface.terra_chal_win_nic.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "WinOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }


  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.Terra_chal_SA.primary_blob_endpoint
  }
}

# Create Linux virtual machine
resource "azurerm_linux_virtual_machine" "terra_chal_linux_vm" {
  name                  = "${var.prefix}linux-vm"
  location              = data.azurerm_resource_group.mbleezarde-sandbox.location
  resource_group_name   = data.azurerm_resource_group.mbleezarde-sandbox.name
  network_interface_ids = [azurerm_network_interface.terra_chal_linux_nic.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "LinuxOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  computer_name  = "hostname"
  admin_username = var.username
  admin_password = azurerm_key_vault_secret.linux_vm_secret.value

  admin_ssh_key {
    username   = var.username
    public_key = jsondecode(azapi_resource_action.ssh_public_key_gen.output).publicKey
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.Terra_chal_SA.primary_blob_endpoint
  }
}

# Generate random text for a unique storage account name
resource "random_id" "random_id" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = data.azurerm_resource_group.mbleezarde-sandbox.name
  }

  byte_length = 8
}

resource "random_password" "password" {
  length      = 20
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  min_special = 1
  special     = true
}

#Create Azure Recovery Services Vault and Backup Policy
#resource "azurerm_recovery_services_vault" "terra_chal_vault" {
#  name                = "${var.prefix}vault"
#  location            = data.azurerm_resource_group.mbleezarde-sandbox.location
#  resource_group_name = data.azurerm_resource_group.mbleezarde-sandbox.name
#  sku                 = "Standard"
#  storage_mode_type   = var.storage_mode_type
#  soft_delete_enabled = true
#}
#
#resource "azurerm_backup_policy_vm" "terra_vm_backup_policy" {
#  name                = var.vm_backup_policy_name
#  resource_group_name = data.azurerm_resource_group.mbleezarde-sandbox.name
#  recovery_vault_name = azurerm_recovery_services_vault.terra_chal_vault.name
#
#  timezone = "UTC"
#
#  backup {
#    frequency = var.vm_backup_policy_frequency
#    time      = var.vm_backup_policy_time
#  }
#
#  retention_daily {
#    count = 10
#  }
#
#  retention_weekly {
#    count    = 42
#    weekdays = ["Sunday", "Wednesday", "Friday", "Saturday"]
#  }
#
#  retention_monthly {
#    count    = 7
#    weekdays = ["Sunday", "Wednesday"]
#    weeks    = ["First", "Last"]
#  }
#
#  retention_yearly {
#    count    = 77
#    weekdays = ["Sunday"]
#    weeks    = ["Last"]
#    months   = ["January"]
#  }
#}

#resource "azurerm_backup_protected_vm" "terra_protected_vm" {
#  resource_group_name = data.azurerm_resource_group.mbleezarde-sandbox.name
#  recovery_vault_name = azurerm_recovery_services_vault.terra_chal_vault.name
#  source_vm_id        = azurerm_windows_virtual_machine.Terra_chal_win_vm.id
#  backup_policy_id    = azurerm_backup_policy_vm.terra_vm_backup_policy.id
#}