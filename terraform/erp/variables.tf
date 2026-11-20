variable "platform" {
  type = object({
    location                     = string
    erp_resource_group_name      = string
    container_app_environment_id = string
    registry_login_server        = string
    key_vault_id                 = string
    mysql_host                   = string
    mysql_database               = string
    service_bus_fqdn             = string
    service_bus_queue_name       = string
    uploads_account_name         = string
    uploads_container_name       = string
    identities = map(object({
      id           = string
      client_id    = string
      principal_id = string
    }))
  })
}

variable "erp_image" {
  type = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9._/-]*@sha256:[a-f0-9]{64}$", var.erp_image))
    error_message = "Use an image reference such as erp@sha256:<64 hex characters>."
  }
}

variable "migration_image" {
  type    = string
  default = null
}

variable "database_users" {
  type = object({
    erp       = string
    relay     = string
    migration = string
  })
  default = {
    erp       = "erp_app"
    relay     = "erp_relay"
    migration = "erp_migrate"
  }
}

variable "secrets" {
  type = object({
    app_key               = string
    erp_db_password       = string
    relay_db_password     = string
    migration_db_password = string
  })
  default = {
    app_key               = "app-key"
    erp_db_password       = "erp-db-password"
    relay_db_password     = "relay-db-password"
    migration_db_password = "migration-db-password"
  }

  validation {
    condition = alltrue([
      for name in values(var.secrets) : can(regex("^[A-Za-z0-9-]{1,127}$", name))
    ]) && length(toset([for name in values(var.secrets) : lower(name)])) == 4
    error_message = "Set four distinct Key Vault names using only letters, numbers, and hyphens."
  }
}

variable "mysql_ca_file" {
  type    = string
  default = "/etc/ssl/certs/ca-certificates.crt"
}

variable "enable_web" {
  type    = bool
  default = false
}

variable "approved_ipv4_cidrs" {
  type    = set(string)
  default = []

  validation {
    condition = alltrue([
      for cidr in var.approved_ipv4_cidrs : try(cidrnetmask(cidr) != "0.0.0.0", false)
    ])
    error_message = "Use specific IPv4 CIDR ranges."
  }
}

variable "web" {
  type = object({
    cpu            = optional(number, 0.5)
    memory         = optional(string, "1Gi")
    min_replicas   = optional(number, 1)
    max_replicas   = optional(number, 2)
    port           = optional(number, 8080)
    startup_path   = optional(string, "/health/live")
    liveness_path  = optional(string, "/health/live")
    readiness_path = optional(string, "/health/ready")
  })
  default = {}
}

variable "web_traffic_revision_suffix" {
  type    = string
  default = null
}

variable "jobs" {
  type = object({
    cpu    = optional(number, 0.5)
    memory = optional(string, "1Gi")
  })
  default = {}
}

variable "migration_command" {
  type = list(string)
}

variable "enable_relay" {
  type    = bool
  default = false
}

variable "relay_command" {
  type    = list(string)
  default = []
}

variable "relay_schedule" {
  type    = string
  default = "* * * * *"
}

variable "web_environment" {
  type    = map(string)
  default = {}

  validation {
    condition     = !contains(keys(var.web_environment), "APP_KEY") && !contains(keys(var.web_environment), "DB_PASSWORD")
    error_message = "APP_KEY and DB_PASSWORD come from Key Vault references."
  }
}
