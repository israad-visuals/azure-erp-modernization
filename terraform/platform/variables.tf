variable "location" {
  type    = string
  default = "canadacentral"
}

variable "name_suffix" {
  type = string
}

variable "mysql_sku" {
  type    = string
  default = "GP_Standard_D2ds_v4"
}

variable "mysql_storage_gb" {
  type    = number
  default = 32
}

variable "backup_days" {
  type    = number
  default = 14
}

variable "mysql_admin_password" {
  type      = string
  sensitive = true
}

variable "storage_redundancy" {
  type    = string
  default = "ZRS"
}

variable "log_daily_gb" {
  type    = number
  default = 1
}

variable "purge_vault" {
  type    = bool
  default = false
}

variable "alert_email" {
  type = string
}

variable "github_subjects" {
  type    = map(string)
  default = {}
}
