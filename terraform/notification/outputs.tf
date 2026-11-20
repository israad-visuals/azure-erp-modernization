output "worker_id" {
  value = azurerm_container_app.worker.id
}

output "worker_name" {
  value = azurerm_container_app.worker.name
}

output "worker_revision" {
  value = azurerm_container_app.worker.latest_revision_name
}

output "verifier_job_name" {
  value = azurerm_container_app_job.verifier.name
}
