terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "5.3.0"
    }
  }
  required_version = ">= 1.11.0"
  backend "azurerm" {
  }
}

provider "azurerm" {
  features {}
}