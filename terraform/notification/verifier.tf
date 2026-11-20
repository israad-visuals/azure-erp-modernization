resource "azurerm_container_app_job" "verifier" {
  name                         = "job-erp-receipt-verifier"
  location                     = var.platform.location
  resource_group_name          = var.platform.notification_resource_group_name
  container_app_environment_id = var.platform.container_app_environment_id
  workload_profile_name        = "Consumption"
  replica_timeout_in_seconds   = 120
  replica_retry_limit          = 0

  identity {
    type         = "UserAssigned"
    identity_ids = [local.verifier_identity.id]
  }

  registry {
    server   = var.platform.registry_login_server
    identity = local.verifier_identity.id
  }

  manual_trigger_config {
    parallelism              = 1
    replica_completion_count = 1
  }

  template {
    container {
      name   = "verifier"
      image  = local.notification_image
      cpu    = 0.25
      memory = "0.5Gi"
      args   = var.verifier_args

      env {
        name  = "AZURE_CLIENT_ID"
        value = local.verifier_identity.client_id
      }

      env {
        name  = "RECEIPTS_TABLE_URI"
        value = local.receipts_table_uri
      }

      env {
        name  = "RECEIPTS_TABLE_NAME"
        value = var.platform.receipts_table_name
      }
    }
  }
}
