output "backends" {
  description = "Backend settings for the platform, ERP and notification roots."
  value = {
    for name, container in azurerm_storage_container.state : name => {
      resource_group_name  = azurerm_resource_group.state.name
      storage_account_name = azurerm_storage_account.state.name
      container_name       = container.name
      key                  = "terraform.tfstate"
      use_azuread_auth     = true
      use_cli              = true
    }
  }
}
