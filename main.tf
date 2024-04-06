
resource "azurerm_resource_group" "mbleezarde-sandbox" {
	name = "mbleezarde-sandbox"
	location = "East US"
	
	}

# Create virtual network
resource "azurerm_virtual_network" "my_terraform_network" {
  name                = "${random_pet.prefix.id}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.mbleezarde-sandbox.location
  resource_group_name = azurerm_resource_group.mbleezarde-sandbox.name
}

# Create Web subnet
resource "azurerm_subnet" "terraform_Web_subnet" {
  name                 = "${random_pet.prefix.id}-Web-subnet"
  resource_group_name  = azurerm_resource_group.mbleezarde-sandbox.name
  virtual_network_name = azurerm_virtual_network.my_terraform_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create Data subnet
resource "azurerm_subnet" "terraform_Data_subnet" {
  name                 = "${random_pet.prefix.id}-Data-subnet"
  resource_group_name  = azurerm_resource_group.mbleezarde-sandbox.name
  virtual_network_name = azurerm_virtual_network.my_terraform_network.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Create Jumpbox subnet
resource "azurerm_subnet" "terraform_Jump_subnet" {
  name                 = "${random_pet.prefix.id}-Jumpbox-subnet"
  resource_group_name  = azurerm_resource_group.mbleezarde-sandbox.name
  virtual_network_name = azurerm_virtual_network.my_terraform_network.name
  address_prefixes     = ["10.0.3.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "my_terraform_public_ip" {
  name                = "${random_pet.prefix.id}-public-ip"
  location            = azurerm_resource_group.mbleezarde-sandbox.location
  resource_group_name = azurerm_resource_group.mbleezarde-sandbox.name
  allocation_method   = "Dynamic"
}

resource "azurerm_public_ip" "my_terraform_Linux_public_ip" {
  name                = "${random_pet.prefix.id}-public-ip"
  location            = azurerm_resource_group.mbleezarde-sandbox.location
  resource_group_name = azurerm_resource_group.mbleezarde-sandbox.name
  allocation_method   = "Dynamic"
}

# Create Network Security Group and rules
resource "azurerm_network_security_group" "my_terraform_nsg" {
  name                = "${random_pet.prefix.id}-nsg"
  location            = azurerm_resource_group.mbleezarde-sandbox.location
  resource_group_name = azurerm_resource_group.mbleezarde-sandbox.name

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
resource "azurerm_network_interface" "my_terraform_nic" {
  name                = "${random_pet.prefix.id}-nic"
  location            = azurerm_resource_group.mbleezarde-sandbox.location
  resource_group_name = azurerm_resource_group.mbleezarde-sandbox.name

  ip_configuration {
    name                          = "my_nic_configuration"
    subnet_id                     = azurerm_subnet.terraform_Web_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.my_terraform_public_ip.id
  }
}

resource "azurerm_network_interface" "my_terraform_linux_nic" {
  name                = "${random_pet.prefix.id}-nic"
  location            = azurerm_resource_group.mbleezarde-sandbox.location
  resource_group_name = azurerm_resource_group.mbleezarde-sandbox.name

  ip_configuration {
    name                          = "my_nic_configuration"
    subnet_id                     = azurerm_subnet.terraform_Data_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.my_terraform_Linux_public_ip.id
  }
}


# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "Windows" {
  network_interface_id      = azurerm_network_interface.my_terraform_nic.id
  network_security_group_id = azurerm_network_security_group.my_terraform_nsg.id
}

resource "azurerm_network_interface_security_group_association" "Linux" {
  network_interface_id      = azurerm_network_interface.my_terraform_linux_nic.id
  network_security_group_id = azurerm_network_security_group.my_terraform_nsg.id
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "my_storage_account" {
  name                     = "diag${random_id.random_id.hex}"
  location                 = azurerm_resource_group.mbleezarde-sandbox.location
  resource_group_name      = azurerm_resource_group.mbleezarde-sandbox.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}


# Create virtual machine
resource "azurerm_windows_virtual_machine" "main" {
  name                  = "${var.prefix}-vm"
  admin_username        = "azureuser"
  admin_password        = random_password.password.result
  location              = azurerm_resource_group.mbleezarde-sandbox.location
  resource_group_name   = azurerm_resource_group.mbleezarde-sandbox.name
  network_interface_ids = [azurerm_network_interface.my_terraform_nic.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "myOsDisk"
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
    storage_account_uri = azurerm_storage_account.my_storage_account.primary_blob_endpoint
  }
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "my_terraform_vm" {
  name                  = "myVM"
  location              = azurerm_resource_group.mbleezarde-sandbox.location
  resource_group_name   = azurerm_resource_group.mbleezarde-sandbox.name
  network_interface_ids = [azurerm_network_interface.my_terraform_linux_nic.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "myLinuxOsDisk"
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
    storage_account_uri = azurerm_storage_account.my_storage_account.primary_blob_endpoint
  }
}

# Generate random text for a unique storage account name
resource "random_id" "random_id" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.mbleezarde-sandbox.name
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

resource "random_pet" "prefix" {
  prefix = var.prefix
  length = 1
}