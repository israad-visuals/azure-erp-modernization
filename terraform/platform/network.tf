resource "azurerm_virtual_network" "erp" {
  name                = "vnet-erp"
  location            = var.location
  resource_group_name = azurerm_resource_group.platform.name
  address_space       = ["10.42.0.0/16"]
}

resource "azurerm_subnet" "app" {
  name                 = "snet-erp-app"
  resource_group_name  = azurerm_resource_group.platform.name
  virtual_network_name = azurerm_virtual_network.erp.name
  address_prefixes     = ["10.42.0.0/26"]

  delegation {
    name = "container-apps"

    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_subnet" "mysql" {
  name                 = "snet-erp-mysql"
  resource_group_name  = azurerm_resource_group.platform.name
  virtual_network_name = azurerm_virtual_network.erp.name
  address_prefixes     = ["10.42.1.0/27"]

  delegation {
    name = "mysql"

    service_delegation {
      name    = "Microsoft.DBforMySQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_subnet" "endpoints" {
  name                 = "snet-erp-endpoints"
  resource_group_name  = azurerm_resource_group.platform.name
  virtual_network_name = azurerm_virtual_network.erp.name
  address_prefixes     = ["10.42.2.0/27"]
}

resource "azurerm_private_dns_zone" "service" {
  for_each = {
    mysql = "erp.mysql.database.azure.com"
    blob  = "privatelink.blob.core.windows.net"
    table = "privatelink.table.core.windows.net"
  }

  name                = each.value
  resource_group_name = azurerm_resource_group.platform.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "erp" {
  for_each = azurerm_private_dns_zone.service

  name                  = "link-erp-${each.key}"
  resource_group_name   = azurerm_resource_group.platform.name
  private_dns_zone_name = each.value.name
  virtual_network_id    = azurerm_virtual_network.erp.id
}

resource "azurerm_private_endpoint" "storage" {
  for_each = {
    blob  = azurerm_storage_account.uploads.id
    table = azurerm_storage_account.receipts.id
  }

  name                = "pe-erp-${each.key}"
  location            = var.location
  resource_group_name = azurerm_resource_group.platform.name
  subnet_id           = azurerm_subnet.endpoints.id

  private_service_connection {
    name                           = each.key
    private_connection_resource_id = each.value
    subresource_names              = [each.key]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = each.key
    private_dns_zone_ids = [azurerm_private_dns_zone.service[each.key].id]
  }
}
