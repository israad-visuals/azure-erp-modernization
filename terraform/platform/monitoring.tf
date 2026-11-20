resource "azurerm_monitor_action_group" "ops" {
  name                = "ag-erp-ops"
  resource_group_name = azurerm_resource_group.platform.name
  short_name          = "erp-ops"

  email_receiver {
    name          = "operator"
    email_address = var.alert_email
  }
}

resource "azurerm_monitor_metric_alert" "dead_letters" {
  name                = "alert-erp-dead-letters"
  resource_group_name = azurerm_resource_group.platform.name
  scopes              = [azurerm_servicebus_namespace.erp.id]
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.ServiceBus/namespaces"
    metric_name      = "DeadletteredMessages"
    aggregation      = "Maximum"
    operator         = "GreaterThan"
    threshold        = 0
  }

  action {
    action_group_id = azurerm_monitor_action_group.ops.id
  }
}

resource "azurerm_monitor_metric_alert" "mysql_cpu" {
  name                = "alert-erp-mysql-cpu"
  resource_group_name = azurerm_resource_group.platform.name
  scopes              = [azurerm_mysql_flexible_server.erp.id]
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.DBforMySQL/flexibleServers"
    metric_name      = "cpu_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.ops.id
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "app_errors" {
  name                  = "alert-erp-app-errors"
  resource_group_name   = azurerm_resource_group.platform.name
  location              = var.location
  scopes                = [azurerm_log_analytics_workspace.erp.id]
  severity              = 2
  evaluation_frequency  = "PT5M"
  window_duration       = "PT5M"
  skip_query_validation = true

  criteria {
    query                   = "ContainerAppConsoleLogs_CL | where Log_s has 'error'"
    time_aggregation_method = "Count"
    operator                = "GreaterThan"
    threshold               = 0

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.ops.id]
  }
}
