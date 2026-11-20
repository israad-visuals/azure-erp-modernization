locals {
  web_identity       = var.platform.identities["erp"]
  relay_identity     = var.platform.identities["relay"]
  migration_identity = var.platform.identities["migration"]
  registry           = var.platform.registry_login_server
  vault_name         = basename(var.platform.key_vault_id)
  secrets_url        = "https://${local.vault_name}.vault.azure.net/secrets"

  secret_access = {
    app_key = {
      name      = var.secrets.app_key
      principal = local.web_identity.principal_id
    }
    erp_db = {
      name      = var.secrets.erp_db_password
      principal = local.web_identity.principal_id
    }
    relay_db = {
      name      = var.secrets.relay_db_password
      principal = local.relay_identity.principal_id
    }
    migration_db = {
      name      = var.secrets.migration_db_password
      principal = local.migration_identity.principal_id
    }
  }

  database_env = {
    APP_ENV           = "production"
    APP_DEBUG         = "false"
    LOG_CHANNEL       = "stderr"
    DB_CONNECTION     = "mysql"
    DB_HOST           = var.platform.mysql_host
    DB_PORT           = "3306"
    DB_DATABASE       = var.platform.mysql_database
    MYSQL_ATTR_SSL_CA = var.mysql_ca_file
  }

  web_env = merge(var.web_environment, local.database_env, {
    DB_USERNAME             = var.database_users.erp
    AZURE_CLIENT_ID         = local.web_identity.client_id
    AZURE_STORAGE_ACCOUNT   = var.platform.uploads_account_name
    AZURE_STORAGE_CONTAINER = var.platform.uploads_container_name
    SESSION_DRIVER          = "database"
    SESSION_SECURE_COOKIE   = "true"
    CACHE_STORE             = "database"
  })

  migration_env = merge(local.database_env, {
    DB_USERNAME = var.database_users.migration
  })

  relay_env = merge(local.database_env, {
    DB_USERNAME            = var.database_users.relay
    AZURE_CLIENT_ID        = local.relay_identity.client_id
    SERVICE_BUS_FQDN       = var.platform.service_bus_fqdn
    SERVICE_BUS_QUEUE_NAME = var.platform.service_bus_queue_name
  })
}
