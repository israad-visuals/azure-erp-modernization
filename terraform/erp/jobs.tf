resource "azurerm_container_app_job" "migration" {
  name                         = "erp-migrate"
  location                     = var.platform.location
  resource_group_name          = var.platform.erp_resource_group_name
  container_app_environment_id = var.platform.container_app_environment_id
  workload_profile_name        = "Consumption"
  replica_timeout_in_seconds   = 600
  replica_retry_limit          = 0

  identity {
    type         = "UserAssigned"
    identity_ids = [local.migration_identity.id]
  }

  registry {
    server   = local.registry
    identity = local.migration_identity.id
  }

  secret {
    name                = "db-password"
    key_vault_secret_id = "${local.secrets_url}/${var.secrets.migration_db_password}"
    identity            = local.migration_identity.id
  }

  manual_trigger_config {
    parallelism              = 1
    replica_completion_count = 1
  }

  template {
    container {
      name    = "migration"
      image   = "${local.registry}/${coalesce(var.migration_image, var.erp_image)}"
      command = var.migration_command
      cpu     = var.jobs.cpu
      memory  = var.jobs.memory

      dynamic "env" {
        for_each = local.migration_env
        content {
          name  = env.key
          value = env.value
        }
      }

      env {
        name        = "DB_PASSWORD"
        secret_name = "db-password"
      }
    }
  }

  lifecycle {
    precondition {
      condition     = length(var.migration_command) > 0
      error_message = "Set the migration command from the ERP image."
    }
  }

  depends_on = [azurerm_role_assignment.secrets]
}

resource "azurerm_container_app_job" "relay" {
  count = var.enable_relay ? 1 : 0

  name                         = "erp-outbox"
  location                     = var.platform.location
  resource_group_name          = var.platform.erp_resource_group_name
  container_app_environment_id = var.platform.container_app_environment_id
  workload_profile_name        = "Consumption"
  replica_timeout_in_seconds   = 60
  replica_retry_limit          = 0

  identity {
    type         = "UserAssigned"
    identity_ids = [local.relay_identity.id]
  }

  registry {
    server   = local.registry
    identity = local.relay_identity.id
  }

  secret {
    name                = "db-password"
    key_vault_secret_id = "${local.secrets_url}/${var.secrets.relay_db_password}"
    identity            = local.relay_identity.id
  }

  schedule_trigger_config {
    cron_expression          = var.relay_schedule
    parallelism              = 1
    replica_completion_count = 1
  }

  template {
    container {
      name    = "relay"
      image   = "${local.registry}/${var.erp_image}"
      command = var.relay_command
      cpu     = var.jobs.cpu
      memory  = var.jobs.memory

      dynamic "env" {
        for_each = local.relay_env
        content {
          name  = env.key
          value = env.value
        }
      }

      env {
        name        = "DB_PASSWORD"
        secret_name = "db-password"
      }
    }
  }

  lifecycle {
    precondition {
      condition     = length(var.relay_command) > 0
      error_message = "Set the outbox relay command before enabling the scheduled job."
    }
  }

  depends_on = [azurerm_role_assignment.secrets]
}
