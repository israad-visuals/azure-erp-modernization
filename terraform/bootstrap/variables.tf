variable "location" {
  description = "Azure region for the state storage account."
  type        = string
  default     = "canadacentral"
}

variable "name_suffix" {
  description = "Unique suffix of lowercase letters and digits for the storage account name."
  type        = string
}
