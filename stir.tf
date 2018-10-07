# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "mystirgroup" {
    name     = "stirGroup"
    location = "${var.location}"

    tags {
        environment = "STIR Demo"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "mystirnetwork" {
    name                = "stirVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "${var.location}"
    resource_group_name = "${azurerm_resource_group.mystirgroup.name}"

    tags {
        environment = "STIR Demo"
    }
}

# Create subnet
resource "azurerm_subnet" "mystirsubnet" {
    name                 = "stirSubnet"
    resource_group_name  = "${azurerm_resource_group.mystirgroup.name}"
    virtual_network_name = "${azurerm_virtual_network.mystirnetwork.name}"
    address_prefix       = "10.0.1.0/24"
}

# Create public IPs
resource "azurerm_public_ip" "mystirpublicip" {
    name                         = "stirPublicIP"
    location                     = "${var.location}"
    resource_group_name          = "${azurerm_resource_group.mystirgroup.name}"
    public_ip_address_allocation = "dynamic"

    tags {
        environment = "STIR Demo"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "mystirsg" {
    name                = "stirNetworkSecurityGroup"
    location            = "${var.location}"
    resource_group_name = "${azurerm_resource_group.mystirgroup.name}"

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags {
        environment = "STIR Demo"
    }
}

# Create network interface
resource "azurerm_network_interface" "mystirnic" {
    name                      = "stirNIC"
    location                  = "${var.location}"
    resource_group_name       = "${azurerm_resource_group.mystirgroup.name}"
    network_security_group_id = "${azurerm_network_security_group.mystirsg.id}"

    ip_configuration {
        name                          = "stirNicConfiguration"
        subnet_id                     = "${azurerm_subnet.mystirsubnet.id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = "${azurerm_public_ip.mystirpublicip.id}"
    }

    tags {
        environment = "STIR Demo"
    }
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = "${azurerm_resource_group.mystirgroup.name}"
    }

    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystirstorageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = "${azurerm_resource_group.mystirgroup.name}"
    location                    = "${var.location}"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags {
        environment = "STIR Demo"
    }
}

# Create virtual machine
resource "azurerm_virtual_machine" "mystirvm" {
    name                  = "stirVM"
    location              = "${var.location}"
    resource_group_name   = "${azurerm_resource_group.mystirgroup.name}"
    network_interface_ids = ["${azurerm_network_interface.mystirnic.id}"]
    vm_size               = "Standard_D2_v2"

    storage_os_disk {
        name              = "stirOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
    }
    
    delete_os_disk_on_termination = true

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "stirvm"
        admin_username = "${var.vm_username}"
        admin_password = "${var.vm_password}"
    }
    
    os_profile_linux_config {
        disable_password_authentication = false
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = "${azurerm_storage_account.mystirstorageaccount.primary_blob_endpoint}"
    }

    provisioner "file" {
        connection {
            user     = "${var.vm_username}"
            password = "${var.vm_password}"
        }
        source      = "provision.sh"
        destination = "/home/${var.vm_username}/provision.sh"
    }

    provisioner "remote-exec" {
        connection {
            user     = "${var.vm_username}"
            password = "${var.vm_password}"
        }

        inline = [
            "sudo do-release-upgrade -f DistUpgradeViewNonInteractive",
            "sudo apt-get install -y cmake build-essential libinsighttoolkit4-dev libboost-all-dev",
            "bash ~/provision.sh"
        ]
    }

    tags {
        environment = "STIR Demo"
    }

}
