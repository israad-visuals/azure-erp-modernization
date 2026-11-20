resource "azurerm_resource_group" "platform" {
  name     = "rg-erp-platform"
  location = var.location
}

resource "azurerm_resource_group" "erp" {
  name     = "rg-erp-app"
  location = var.location
}

resource "azurerm_resource_group" "notification" {
  name     = "rg-erp-notification"
  location = var.location
}
