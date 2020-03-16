# Create virtual machine
resource "azurerm_virtual_machine" "telemetryserver" {
  count                 = 1
  name                  = format("%s-telemetryserver-%s-%s", var.prefix, count.index, random_id.randomId.hex)
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.telemetry_nic[count.index].id]
  vm_size               = var.telemetrysvr_instance_type
  zones                 = [element(local.azs, count.index)]

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # if this is set to false there are behaviors that will require manual intervention
  # if tainting the virtual machine
  delete_os_disk_on_termination = true


  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_os_disk {
    name              = format("%s-telemetryserver-%s-%s", var.prefix, count.index, random_id.randomId.hex)
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = format("%s-telemetryserver-%s-%s", var.prefix, count.index, random_id.randomId.hex)
    admin_username = "azureuser"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/azureuser/.ssh/authorized_keys"
      key_data = file(var.publickeyfile)
    }
  }

  boot_diagnostics {
    enabled     = "true"
    storage_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
  }

  tags = {
    environment = var.specification[terraform.workspace]["environment"]
    workload    = "grafana"
  }
}

# Create network interface
resource "azurerm_network_interface" "telemetry_nic" {
  count                     = 1
  name                      = format("%s-telemetry_nic-%s-%s", var.prefix, count.index, random_id.randomId.hex)
  location                  = azurerm_resource_group.main.location
  resource_group_name       = azurerm_resource_group.main.name
  #network_security_group_id = azurerm_network_security_group.app_sg.id

  ip_configuration {
    name                          = format("%s-telemetry_nic-%s-%s", var.prefix, count.index, random_id.randomId.hex)
    subnet_id                     = azurerm_subnet.private[count.index % length(local.azs)].id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    environment = var.specification[terraform.workspace]["environment"]
    application = "grafana"
  }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "telemetry_sg" {
  name                = format("%s-telemetry_sg-%s", var.prefix, random_id.randomId.hex)
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # extend the set of security rules to address the needs of
  # the applications deployed on the application server
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = local.cidr # only allow traffic from within the virtual network
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "elasticsearch-1"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9300"
    source_address_prefix      = local.cidr # only allow traffic from within the virtual network
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "elasticsearch-2"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9200"
    source_address_prefix      = local.cidr # only allow traffic from within the virtual network
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "graphite-1"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = local.cidr # only allow traffic from within the virtual network
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "graphite-2"
    priority                   = 1005
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8126"
    source_address_prefix      = local.cidr # only allow traffic from within the virtual network
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "graphite-3"
    priority                   = 1006
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "8125"
    source_address_prefix      = local.cidr # only allow traffic from within the virtual network
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "graphite-4"
    priority                   = 1007
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "2024"
    source_address_prefix      = local.cidr # only allow traffic from within the virtual network
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "graphite-5"
    priority                   = 1008
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "2023"
    source_address_prefix      = local.cidr # only allow traffic from within the virtual network
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "graphite-6"
    priority                   = 1009
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "2004"
    source_address_prefix      = local.cidr # only allow traffic from within the virtual network
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "graphite-7"
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "2003"
    source_address_prefix      = local.cidr # only allow traffic from within the virtual network
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "graphite-8"
    priority                   = 1011
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3400"
    source_address_prefix      = local.cidr # only allow traffic from within the virtual network
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "grafana-1"
    priority                   = 1012
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3030"
    source_address_prefix      = local.cidr # only allow traffic from within the virtual network
    destination_address_prefix = "*"
  }

  tags = {
    environment = var.specification[terraform.workspace]["environment"]
  }
}
