
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


# Create virtual machine
resource "azurerm_windows_virtual_machine" "Terra_chal_win_vm" {
  name                  = "${var.prefix}vm"
  admin_username        = "azureuser"
  admin_password        = random_password.password.result
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
resource "azurerm_recovery_services_vault" "terra_chal_vault" {
  name                = "${var.prefix}vault"
  location            = data.azurerm_resource_group.mbleezarde-sandbox.location
  resource_group_name = data.azurerm_resource_group.mbleezarde-sandbox.name
  sku                 = "Standard"
  storage_mode_type   = var.storage_mode_type
  soft_delete_enabled = true
}

resource "azurerm_backup_policy_file_share" "terra_chal_backup_policy" {
  for_each = var.backup_policies

  name                = each.value.name
  resource_group_name = data.azurerm_resource_group.mbleezarde-sandbox.name
  recovery_vault_name = azurerm_recovery_services_vault.terra_chal_vault.name

  backup {
    frequency = each.value.frequency
    time      = each.value.time
  }

  retention_daily {
    count = each.value.retention_daily
  }

  retention_weekly {
    count    = each.value.retention_weekly
    weekdays = ["Sunday"]
  }

  retention_monthly {
    count    = each.value.retention_monthly
    weekdays = ["Sunday"]
    weeks    = ["First"]
  }

  retention_yearly {
    count    = each.value.retention_yearly
    weekdays = ["Sunday"]
    weeks    = ["First"]
    months   = toset(["January"])
  }
}