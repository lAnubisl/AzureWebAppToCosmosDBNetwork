terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.62.0"
    }
  }
  required_version = ">= 1.11.0"
  backend "azurerm" {
  }
}

provider "azurerm" {
  features {}
}