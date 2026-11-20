resource "azurerm_user_assigned_identity" "release" {
  for_each = var.github_subjects

  name                = "id-erp-release-${each.key}"
  location            = var.location
  resource_group_name = azurerm_resource_group.platform.name
}

resource "azurerm_federated_identity_credential" "github" {
  for_each = azurerm_user_assigned_identity.release

  name                      = "github"
  user_assigned_identity_id = each.value.id
  issuer                    = "https://token.actions.githubusercontent.com"
  audience                  = ["api://AzureADTokenExchange"]
  subject                   = var.github_subjects[each.key]
}

resource "azurerm_role_assignment" "publish_images" {
  for_each = azurerm_user_assigned_identity.release

  scope                = azurerm_container_registry.erp.id
  role_definition_name = "AcrPush"
  principal_id         = each.value.principal_id
  principal_type       = "ServicePrincipal"
}
