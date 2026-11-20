output "erp_url" {
  value = var.enable_web ? "https://${azurerm_container_app.web[0].ingress[0].fqdn}" : null
}

output "web_revision_name" {
  value = var.enable_web ? azurerm_container_app.web[0].latest_revision_name : null
}

output "migration_job_name" {
  value = azurerm_container_app_job.migration.name
}

output "relay_job_name" {
  value = var.enable_relay ? azurerm_container_app_job.relay[0].name : null
}
