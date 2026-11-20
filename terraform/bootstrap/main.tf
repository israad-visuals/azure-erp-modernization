data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "state" {
  name     = "rg-erp-state"
  location = var.location
}

resource "azurerm_storage_account" "state" {
  name                            = "sterpstate${var.name_suffix}"
  resource_group_name             = azurerm_resource_group.state.name
  location                        = azurerm_resource_group.state.location
  account_kind                    = "StorageV2"
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false
  default_to_oauth_authentication = true
}

resource "azurerm_storage_container" "state" {
  for_each = toset(["platform", "erp", "notification"])

  name                  = each.key
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"
}

resource "azurerm_role_assignment" "state_operator" {
  for_each = azurerm_storage_container.state

  scope                = each.value.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}
