terraform {
  required_providers {

    azurerm={
        source = "hashicorp/azurerm"
        version = "3.99.0"
    }
  }
}
#configure the microsoft azure provider
provider "azurerm" {
    features {
      
    } 
     subscription_id = var.subscription_id
     client_id = var.client_id
     client_secret = var.client_secret
     tenant_id = var.tenant_id
}
#create resource group
resource "azurerm_resource_group" "devrg002" {
    name = "mydevrg002"
    location = "eastus"
  
}

resource "azurerm_virtual_network" "devvnet002"{
 
  name = "devvnet002"
  resource_group_name = azurerm_resource_group.devrg002.name
  location = azurerm_resource_group.devrg002.location
  address_space = ["10.50.0.0/16"]
}
resource "azurerm_subnet" "subnet1" {
  name                 = "devsubnet1"
  resource_group_name  = azurerm_resource_group.devrg002.name
  virtual_network_name = azurerm_virtual_network.devvnet002.name
  address_prefixes     = ["10.50.1.0/24"]
}
resource "azurerm_public_ip" "mydevip002" {
  count =var.vm_count
  name = "${var.vm_name_pfx}-${count.index}-ip"
  location = azurerm_resource_group.devrg002.location
  resource_group_name = azurerm_resource_group.devrg002.name
   allocation_method = "Static"
}
resource "azurerm_network_security_group" "nsg1" {
  name ="mydev.nsg1"
  resource_group_name = azurerm_resource_group.devrg002.name
  location = azurerm_resource_group.devrg002.location
  
}
# Note:this allows RDP from any network 
resource "azurerm_network_security_rule" "ssh" {
  name = "ssh"
  resource_group_name = azurerm_resource_group.devrg002.name
  network_security_group_name = azurerm_network_security_group.nsg1.name
  priority = 102
  direction = "Inbound"
  access = "Allow"
  protocol = "Tcp"
  source_port_range = "*"
  destination_port_range = "22"
  source_address_prefix = "*"
  destination_address_prefix = "*"
  
}
    
resource "azurerm_subnet_network_security_group_association" "nsg_subnet_assoc"{
  subnet_id = azurerm_subnet.subnet1.id
  network_security_group_id = azurerm_network_security_group.nsg1.id

}
resource "azurerm_network_interface" "nici" {
  count = var.vm_count
  name = "${var.vm_name_pfx}-${count.index}-nic"
  resource_group_name = azurerm_resource_group.devrg002.name
  location = azurerm_resource_group.devrg002.location

  ip_configuration {
    
    name ="internal"
    subnet_id = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id= azurerm_public_ip.mydevip002[count.index].id
  }
  
}
resource "azurerm_linux_virtual_machine" "devVM" {
  count = var.vm_count
 name ="${var.vm_name_pfx}-${count.index}"
 resource_group_name = azurerm_resource_group.devrg002.name
 location = azurerm_resource_group.devrg002.location
 size = "standard_b1s"
 admin_username = "appadmin"
 admin_password = "Manoj@15122000"
 disable_password_authentication = false
 network_interface_ids = [ azurerm_network_interface.nici[count.index].id ]
 
 
 
source_image_reference {
  publisher = "canonical"
  offer = "ubuntuserver"
  sku = "18.04-lts"
  version = "latest"
   
 }
 os_disk {
   storage_account_type = "Standard_LRS"
   caching = "ReadWrite"

 }
}
