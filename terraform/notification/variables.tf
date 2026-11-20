variable "platform" {
  type = object({
    location                         = string
    notification_resource_group_name = string
    container_app_environment_id     = string
    registry_login_server            = string
    service_bus_fqdn                 = string
    service_bus_queue_name           = string
    receipts_account_name            = string
    receipts_table_name              = string
    identities = map(object({
      id           = string
      client_id    = string
      principal_id = string
    }))
  })
}

variable "notification_image" {
  type = string

  validation {
    condition     = can(regex("^[a-z0-9./_-]+@sha256:[a-f0-9]{64}$", var.notification_image))
    error_message = "Use a registry-relative image reference like notification@sha256:<64 hex digits>."
  }
}

variable "worker_replicas" {
  type    = number
  default = 1
}

variable "worker_size" {
  type = object({
    cpu    = number
    memory = string
  })

  default = {
    cpu    = 0.5
    memory = "1Gi"
  }
}

variable "verifier_args" {
  type    = list(string)
  default = ["verify"]
}
