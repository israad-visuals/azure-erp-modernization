resource "azurerm_user_assigned_identity" "app" {
  for_each = {
    erp       = azurerm_resource_group.erp.name
    relay     = azurerm_resource_group.erp.name
    migration = azurerm_resource_group.erp.name
    worker    = azurerm_resource_group.notification.name
    verifier  = azurerm_resource_group.notification.name
  }

  name                = "id-erp-${each.key}"
  location            = var.location
  resource_group_name = each.value
}

resource "azurerm_role_assignment" "registry_pull" {
  for_each = azurerm_user_assigned_identity.app

  scope                = azurerm_container_registry.erp.id
  role_definition_name = "AcrPull"
  principal_id         = each.value.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "send_invoices" {
  scope                = azurerm_servicebus_queue.invoices.id
  role_definition_name = "Azure Service Bus Data Sender"
  principal_id         = azurerm_user_assigned_identity.app["relay"].principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "receive_invoices" {
  scope                = azurerm_servicebus_queue.invoices.id
  role_definition_name = "Azure Service Bus Data Receiver"
  principal_id         = azurerm_user_assigned_identity.app["worker"].principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "uploads" {
  scope                = azurerm_storage_container.uploads.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.app["erp"].principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "write_receipts" {
  scope                = azapi_resource.receipts.id
  role_definition_name = "Storage Table Data Contributor"
  principal_id         = azurerm_user_assigned_identity.app["worker"].principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "read_receipts" {
  scope                = azapi_resource.receipts.id
  role_definition_name = "Storage Table Data Reader"
  principal_id         = azurerm_user_assigned_identity.app["verifier"].principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "vault_operator" {
  scope                = azurerm_key_vault.erp.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}
