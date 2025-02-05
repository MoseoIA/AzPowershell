variable "resource_group_name" {
  description = "The name of the resource group where the Logic App will be created."
  type        = string
}

variable "location" {
  description = "The Azure region where the resources will be deployed."
  type        = string
}

variable "logic_app_name" {
  description = "The name of the Logic App."
  type        = string
}

variable "storage_account_name" {
  description = "The name of the storage account to be used with the Logic App Standard."
  type        = string
}

variable "environment" {
  description = "The environment tag (e.g., dev, prod)."
  type        = string
  default     = "dev"
}
