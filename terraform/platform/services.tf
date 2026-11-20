resource "azurerm_log_analytics_workspace" "erp" {
  name                = "log-erp-${var.name_suffix}"
  resource_group_name = azurerm_resource_group.platform.name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  daily_quota_gb      = var.log_daily_gb
}

resource "azurerm_container_app_environment" "erp" {
  name                       = "cae-erp"
  resource_group_name        = azurerm_resource_group.platform.name
  location                   = var.location
  infrastructure_subnet_id   = azurerm_subnet.app.id
  logs_destination           = "log-analytics"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.erp.id

  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }
}

resource "azurerm_container_registry" "erp" {
  name                                         = "crerp${var.name_suffix}"
  resource_group_name                          = azurerm_resource_group.platform.name
  location                                     = var.location
  sku                                          = "Basic"
  admin_enabled                                = false
  azuread_authentication_as_arm_policy_enabled = true
  role_assignment_mode                         = "LegacyRegistryPermissions"
}

resource "azurerm_key_vault" "erp" {
  name                       = "kv-erp-${var.name_suffix}"
  resource_group_name        = azurerm_resource_group.platform.name
  location                   = var.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  soft_delete_retention_days = 7
}
