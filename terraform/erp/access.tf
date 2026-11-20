resource "azurerm_role_assignment" "secrets" {
  for_each = local.secret_access

  scope                            = "${var.platform.key_vault_id}/secrets/${each.value.name}"
  role_definition_name             = "Key Vault Secrets User"
  principal_id                     = each.value.principal
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}
