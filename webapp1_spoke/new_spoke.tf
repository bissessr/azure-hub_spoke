locals {
  webapp1-location        = "EastUS"
  hub-location            = "EastUS"
  webapp1-resource-group  = "webapp1-vnet-rg"
  prefix-webapp1          = "webapp1"
  prefix-hub              = "hub"
  hub-resource-group      = "hub-vnet-rg"
  shared-key              = "4-v3ry-53cr37-1p53c-5h4r3d-k3y"
}


resource "azurerm_resource_group" "hub-vnet-rg" {
  name     = "${local.hub-resource-group}"
  location = "${local.hub-location}"
}

resource "azurerm_virtual_network" "hub-vnet" {
  name                = "${local.prefix-hub}-vnet"
  location            = "${azurerm_resource_group.hub-vnet-rg.location}"
  resource_group_name = "${azurerm_resource_group.hub-vnet-rg.name}"
  address_space       = ["10.0.0.0/16"]

  tags {
    environment = "hub-spoke"
  }
}

resource "azurerm_virtual_network_gateway" "hub-vnet-gateway" {
  name                = "hub-vpn-gateway1"
  location            = "${azurerm_resource_group.hub-vnet-rg.location}"
  resource_group_name = "${azurerm_resource_group.hub-vnet-rg.name}"

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "VpnGw1"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = "${azurerm_public_ip.hub-vpn-gateway1-pip.id}"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = "${azurerm_subnet.hub-gateway-subnet.id}"
  }
   depends_on = ["azurerm_public_ip.hub-vpn-gateway1-pip"]
}

resource "azurerm_resource_group" "webapp1-vnet-rg" {
  name     = "${local.webapp1-resource-group}"
  location = "${local.webapp1-location}"
}

resource "azurerm_virtual_network" "webapp1-vnet" {
  name                = "${local.prefix-webapp1}-vnet"
  location            = "${azurerm_resource_group.webapp1-vnet-rg.location}"
  resource_group_name = "${azurerm_resource_group.webapp1-vnet-rg.name}"
  # increment with each additonal Application
  address_space       = ["10.3.0.0/16"]

  tags {
    environment = "${local.prefix-webapp1}"
  }
}

# Create Managment Subnet
resource "azurerm_subnet" "webapp1-mgmt" {
  name                 = "mgmt"
  resource_group_name  = "${azurerm_resource_group.webapp1-vnet-rg.name}"
  virtual_network_name = "${azurerm_virtual_network.webapp1-vnet.name}"
  # increment with each additonal Application
  address_prefix       = "10.3.0.64/27" 
}

resource "azurerm_subnet" "hub-gateway-subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = "${azurerm_resource_group.hub-vnet-rg.name}"
  virtual_network_name = "${azurerm_virtual_network.hub-vnet.name}"
  address_prefix       = "10.0.255.224/27"
}

# Create Workload Subnet
resource "azurerm_subnet" "webapp1-workload" {
  name                 = "workload"
  resource_group_name  = "${azurerm_resource_group.webapp1-vnet-rg.name}"
  virtual_network_name = "${azurerm_virtual_network.webapp1-vnet.name}"
  # increment with each additonal Application
  address_prefix       = "10.3.1.0/24"
}

# Virtual Network Gateway
resource "azurerm_public_ip" "hub-vpn-gateway1-pip" {
  name                = "hub-vpn-gateway1-pip"
  location            = "${azurerm_resource_group.hub-vnet-rg.location}"
  resource_group_name = "${azurerm_resource_group.hub-vnet-rg.name}"

  allocation_method = "Dynamic"
}


resource "azurerm_virtual_network_peering" "webapp1-hub-peer" {
  name                      = "webapp1-hub-peer"
  resource_group_name       = "${azurerm_resource_group.webapp1-vnet-rg.name}"
  virtual_network_name      = "${azurerm_virtual_network.webapp1-vnet.name}"
  remote_virtual_network_id = "${azurerm_virtual_network.hub-vnet.id}"

  allow_virtual_network_access = true
  allow_forwarded_traffic = true
  allow_gateway_transit   = false
  use_remote_gateways     = true
  depends_on = ["azurerm_virtual_network.webapp1-vnet", "azurerm_virtual_network.hub-vnet", "azurerm_virtual_network_gateway.hub-vnet-gateway"]
}



resource "azurerm_network_interface" "webapp1-nic" {
  name                 = "${local.prefix-webapp1}-nic"
  location             = "${azurerm_resource_group.webapp1-vnet-rg.location}"
  resource_group_name  = "${azurerm_resource_group.webapp1-vnet-rg.name}"
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "${local.prefix-webapp1}"
    subnet_id                     = "${azurerm_subnet.webapp1-mgmt.id}"
    private_ip_address_allocation = "Dynamic"
  }

  tags {
    environment = "${local.prefix-webapp1}"
  }
}

resource "azurerm_virtual_machine" "webapp1-vm" {
  name                  = "${local.prefix-webapp1}-vm"
  location              = "${azurerm_resource_group.webapp1-vnet-rg.location}"
  resource_group_name   = "${azurerm_resource_group.webapp1-vnet-rg.name}"
  network_interface_ids = ["${azurerm_network_interface.webapp1-nic.id}"]
  vm_size               = "${var.vmsize}"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${local.prefix-webapp1}-vm"
    admin_username = "${var.username}"
    admin_password = "${var.password}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags {
    environment = "${local.prefix-webapp1}"
  }
}


resource "azurerm_virtual_network_peering" "hub-webapp1-peer" {
  name                      = "hub-webapp1-peer"
  resource_group_name       = "${azurerm_resource_group.hub-vnet-rg.name}"
  virtual_network_name      = "${azurerm_virtual_network.hub-vnet.name}"
  remote_virtual_network_id = "${azurerm_virtual_network.webapp1-vnet.id}"

  allow_virtual_network_access = true
  allow_forwarded_traffic = true
  allow_gateway_transit   = true
  use_remote_gateways     = false
  depends_on = ["azurerm_virtual_network.webapp1-vnet", "azurerm_virtual_network.hub-vnet", "azurerm_virtual_network_gateway.hub-vnet-gateway"]
}


# setup Workloads (WebServers)
resource "random_string" "fqdn" {
 length  = 6
 special = false
 upper   = false
 number  = false
}

resource "azurerm_public_ip" "webapp1-workload"{
 name                = "webapp1-public-ip"
 location            = "${var.location}"
 resource_group_name = "${azurerm_resource_group.webapp1-vnet-rg.name}"
 allocation_method   = "Static"
 domain_name_label   = "${random_string.fqdn.result}"
 tags                = "${var.tags}"
}

resource "azurerm_lb" "webapp1-workload" {
 name                = "webapp1-workload-lb"
 location            = "${var.location}"
 resource_group_name = "${azurerm_resource_group.webapp1-vnet-rg.name}"

 frontend_ip_configuration {
   name                 = "PublicIPAddress"
   public_ip_address_id = "${azurerm_public_ip.webapp1-workload.id}"
 }

 tags = "${var.tags}"
}

resource "azurerm_lb_backend_address_pool" "bpepool" {
 resource_group_name = "${azurerm_resource_group.webapp1-vnet-rg.name}"
 loadbalancer_id     = "${azurerm_lb.webapp1-workload.id}"
 name                = "BackEndAddressPool"
}

resource "azurerm_lb_probe" "webapp1-workload" {
 resource_group_name = "${azurerm_resource_group.webapp1-vnet-rg.name}"
 loadbalancer_id     = "${azurerm_lb.webapp1-workload.id}"
 name                = "ssh-running-probe"
 port                = "${var.application_port}"
}

resource "azurerm_lb_rule" "lbnatrule" {
 resource_group_name            = "${azurerm_resource_group.webapp1-vnet-rg.name}"
 loadbalancer_id                = "${azurerm_lb.webapp1-workload.id}"
 name                           = "http"
 protocol                       = "Tcp"
 frontend_port                  = "${var.application_port}"
 backend_port                   = "${var.application_port}"
 backend_address_pool_id        = "${azurerm_lb_backend_address_pool.bpepool.id}"
 frontend_ip_configuration_name = "PublicIPAddress"
 probe_id                       = "${azurerm_lb_probe.webapp1-workload.id}"
}

resource "azurerm_virtual_machine_scale_set" "webapp1-workload" {
 name                = "webapp1-scaleset"
 location            = "${var.location}"
 resource_group_name = "${azurerm_resource_group.webapp1-vnet-rg.name}"
 upgrade_policy_mode = "Manual"

 sku {
   name     = "Standard_DS1_v2"
   tier     = "Standard"
   capacity = 2
 }

 storage_profile_image_reference {
   publisher = "Canonical"
   offer     = "UbuntuServer"
   sku       = "16.04-LTS"
   version   = "latest"
 }

 storage_profile_os_disk {
   name              = ""
   caching           = "ReadWrite"
   create_option     = "FromImage"
   managed_disk_type = "Standard_LRS"
 }

 storage_profile_data_disk {
   lun          = 0
   caching        = "ReadWrite"
   create_option  = "Empty"
   disk_size_gb   = 10
 }

 os_profile {
   computer_name_prefix = "vmlab"
   admin_username       = "${var.username}"
   admin_password       = "${var.password}"
   custom_data          = "${file("web.conf")}"
 }

 os_profile_linux_config {
   disable_password_authentication = false
 }

 network_profile {
   name    = "terraformnetworkprofile"
   primary = true

   ip_configuration {
     name                                   = "IPConfiguration"
     subnet_id                              = "${azurerm_subnet.webapp1-workload.id}"
     load_balancer_backend_address_pool_ids = ["${azurerm_lb_backend_address_pool.bpepool.id}"]
     primary = true
   }
 }

 tags = "${var.tags}"
}

