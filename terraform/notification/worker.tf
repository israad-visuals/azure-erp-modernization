locals {
  worker_identity    = var.platform.identities["worker"]
  verifier_identity  = var.platform.identities["verifier"]
  notification_image = "${var.platform.registry_login_server}/${var.notification_image}"
  receipts_table_uri = "https://${var.platform.receipts_account_name}.table.core.windows.net"
}

resource "azurerm_container_app" "worker" {
  name                         = "ca-erp-notification"
  resource_group_name          = var.platform.notification_resource_group_name
  container_app_environment_id = var.platform.container_app_environment_id
  workload_profile_name        = "Consumption"
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [local.worker_identity.id]
  }

  registry {
    server   = var.platform.registry_login_server
    identity = local.worker_identity.id
  }

  template {
    min_replicas = var.worker_replicas
    max_replicas = var.worker_replicas

    container {
      name   = "worker"
      image  = local.notification_image
      cpu    = var.worker_size.cpu
      memory = var.worker_size.memory

      env {
        name  = "AZURE_CLIENT_ID"
        value = local.worker_identity.client_id
      }

      env {
        name  = "SERVICE_BUS_FQDN"
        value = var.platform.service_bus_fqdn
      }

      env {
        name  = "SERVICE_BUS_QUEUE_NAME"
        value = var.platform.service_bus_queue_name
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
