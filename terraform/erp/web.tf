resource "azurerm_container_app" "web" {
  count = var.enable_web ? 1 : 0

  name                         = "erp-web"
  resource_group_name          = var.platform.erp_resource_group_name
  container_app_environment_id = var.platform.container_app_environment_id
  workload_profile_name        = "Consumption"
  revision_mode                = "Multiple"

  identity {
    type         = "UserAssigned"
    identity_ids = [local.web_identity.id]
  }

  registry {
    server   = local.registry
    identity = local.web_identity.id
  }

  secret {
    name                = "app-key"
    key_vault_secret_id = "${local.secrets_url}/${var.secrets.app_key}"
    identity            = local.web_identity.id
  }

  secret {
    name                = "db-password"
    key_vault_secret_id = "${local.secrets_url}/${var.secrets.erp_db_password}"
    identity            = local.web_identity.id
  }

  ingress {
    external_enabled           = true
    allow_insecure_connections = false
    target_port                = var.web.port
    transport                  = "http"

    dynamic "ip_security_restriction" {
      for_each = var.approved_ipv4_cidrs

      content {
        name             = "reviewer-${replace(replace(ip_security_restriction.value, ".", "-"), "/", "-")}"
        ip_address_range = ip_security_restriction.value
        action           = "Allow"
      }
    }

    traffic_weight {
      latest_revision = var.web_traffic_revision_suffix == null
      revision_suffix = var.web_traffic_revision_suffix
      percentage      = 100
    }
  }

  template {
    min_replicas = var.web.min_replicas
    max_replicas = var.web.max_replicas

    container {
      name   = "erp"
      image  = "${local.registry}/${var.erp_image}"
      cpu    = var.web.cpu
      memory = var.web.memory

      dynamic "env" {
        for_each = local.web_env
        content {
          name  = env.key
          value = env.value
        }
      }

      env {
        name        = "APP_KEY"
        secret_name = "app-key"
      }

      env {
        name        = "DB_PASSWORD"
        secret_name = "db-password"
      }

      startup_probe {
        transport               = "HTTP"
        port                    = var.web.port
        path                    = var.web.startup_path
        interval_seconds        = 5
        failure_count_threshold = 24
      }

      liveness_probe {
        transport = "HTTP"
        port      = var.web.port
        path      = var.web.liveness_path
      }

      readiness_probe {
        transport               = "HTTP"
        port                    = var.web.port
        path                    = var.web.readiness_path
        success_count_threshold = 1
      }
    }
  }

  lifecycle {
    precondition {
      condition     = length(var.approved_ipv4_cidrs) > 0
      error_message = "Set at least one approved IPv4 CIDR before enabling the ERP web app."
    }
  }

  depends_on = [azurerm_role_assignment.secrets]
}
