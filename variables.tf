# --- variables.tf en Mod_AzDatabricks_Native ---

variable "resource_group_name" {
  type        = string
  description = "Nombre del grupo de recursos donde se creará el Databricks."
}

variable "workspace_name" {
  type        = string
  description = "Nombre para el espacio de trabajo de Databricks."
}

variable "managed_resource_group_name" {
  type        = string
  description = "Nombre del grupo de recursos gestionado por Databricks."
}

variable "sku" {
  type        = string
  default     = "premium"
  description = "SKU para el workspace. 'premium' es requerido para Private Link y VNet Injection."
}

variable "databricks_vnet_name" {
  type        = string
  description = "Nombre de la VNet para las subnets de Databricks."
}

variable "databricks_vnet_rg_name" {
  type        = string
  description = "Nombre del grupo de recursos de la VNet de Databricks."
}

variable "databricks_public_subnet_name" {
  type        = string
  description = "Nombre de la subnet pública para Databricks."
}

variable "databricks_private_subnet_name" {
  type        = string
  description = "Nombre de la subnet privada para Databricks."
}

variable "private_endpoint_vnet_name" {
  type        = string
  description = "Nombre de la VNet donde se creará el Private Endpoint."
}

variable "private_endpoint_vnet_rg_name" {
  type        = string
  description = "Nombre del grupo de recursos de la VNet del Private Endpoint."
}

variable "private_endpoint_subnet_name" {
  type        = string
  description = "Nombre de la subnet para el Private Endpoint."
}

variable "private_dns_zone_id_databricks" {
  type        = string
  description = "ID de la Private DNS Zone para Databricks (privatelink.azuredatabricks.net)."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Etiquetas a aplicar a los recursos."
}
