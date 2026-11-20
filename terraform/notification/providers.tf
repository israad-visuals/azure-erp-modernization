terraform {
  required_version = ">= 1.8.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81, < 5.0"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {}

  resource_provider_registrations = "none"
}
