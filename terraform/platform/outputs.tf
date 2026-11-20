output "platform" {
  value = {
    location                         = var.location
    erp_resource_group_name          = azurerm_resource_group.erp.name
    notification_resource_group_name = azurerm_resource_group.notification.name
    container_app_environment_id     = azurerm_container_app_environment.erp.id
    registry_login_server            = azurerm_container_registry.erp.login_server
    key_vault_id                     = azurerm_key_vault.erp.id
    key_vault_name                   = azurerm_key_vault.erp.name
    mysql_host                       = azurerm_mysql_flexible_server.erp.fqdn
    mysql_database                   = azurerm_mysql_flexible_database.erp.name
    service_bus_fqdn                 = "${azurerm_servicebus_namespace.erp.name}.servicebus.windows.net"
    service_bus_queue_name           = azurerm_servicebus_queue.invoices.name
    uploads_account_name             = azurerm_storage_account.uploads.name
    uploads_container_name           = azurerm_storage_container.uploads.name
    receipts_account_name            = azurerm_storage_account.receipts.name
    receipts_table_name              = azapi_resource.receipts.name
    identities = {
      for name, identity in azurerm_user_assigned_identity.app : name => {
        id           = identity.id
        client_id    = identity.client_id
        principal_id = identity.principal_id
      }
    }
  }
}

output "release_client_ids" {
  value = {
    for name, identity in azurerm_user_assigned_identity.release : name => identity.client_id
  }
}
