resource "azurerm_mysql_flexible_server" "erp" {
  name                   = "mysql-erp-${var.name_suffix}"
  resource_group_name    = azurerm_resource_group.platform.name
  location               = var.location
  administrator_login    = "erpadmin"
  administrator_password = var.mysql_admin_password
  sku_name               = var.mysql_sku
  version                = "8.0.21"
  delegated_subnet_id    = azurerm_subnet.mysql.id
  private_dns_zone_id    = azurerm_private_dns_zone.service["mysql"].id
  backup_retention_days  = var.backup_days
  public_network_access  = "Disabled"

  storage {
    size_gb           = var.mysql_storage_gb
    auto_grow_enabled = true
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.erp]
}

resource "azurerm_mysql_flexible_database" "erp" {
  name                = "erp"
  resource_group_name = azurerm_resource_group.platform.name
  server_name         = azurerm_mysql_flexible_server.erp.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}

resource "azurerm_storage_account" "uploads" {
  name                            = "sterpupload${var.name_suffix}"
  resource_group_name             = azurerm_resource_group.platform.name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = var.storage_redundancy
  public_network_access_enabled   = false
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = var.backup_days
    }

    container_delete_retention_policy {
      days = var.backup_days
    }
  }
}

resource "azurerm_storage_container" "uploads" {
  name                  = "uploads"
  storage_account_id    = azurerm_storage_account.uploads.id
  container_access_type = "private"
}

resource "azurerm_storage_account" "receipts" {
  name                            = "sterpreceipt${var.name_suffix}"
  resource_group_name             = azurerm_resource_group.platform.name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = var.storage_redundancy
  public_network_access_enabled   = false
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false
}

resource "azapi_resource" "receipts" {
  type      = "Microsoft.Storage/storageAccounts/tableServices/tables@2023-05-01"
  name      = "receipts"
  parent_id = "${azurerm_storage_account.receipts.id}/tableServices/default"
  body      = { properties = {} }
}

resource "azurerm_servicebus_namespace" "erp" {
  name                = "sb-erp-${var.name_suffix}"
  resource_group_name = azurerm_resource_group.platform.name
  location            = var.location
  sku                 = "Standard"
  local_auth_enabled  = false
}

resource "azurerm_servicebus_queue" "invoices" {
  name                                    = "invoice-events"
  namespace_id                            = azurerm_servicebus_namespace.erp.id
  requires_duplicate_detection            = true
  duplicate_detection_history_time_window = "PT10M"
  lock_duration                           = "PT1M"
  max_delivery_count                      = 5
  dead_lettering_on_message_expiration    = true
}
