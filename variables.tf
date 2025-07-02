# --- variables.tf en Mod_AzDatabricks_Native ---
# Este archivo define todas las variables de entrada que el módulo acepta.

# --- Variables del Workspace de Databricks ---

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
  description = "Nombre del grupo de recursos que será gestionado por Databricks."
}

variable "sku" {
  type        = string
  default     = "premium"
  description = "SKU para el workspace. 'premium' es requerido para Private Link y VNet Injection."
}

# --- Variables de Red para Databricks (VNet Injection) ---

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

# --- Variables de Red para el Private Endpoint ---

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

# --- Variable de DNS Privado ---

variable "private_dns_zone_id_databricks" {
  type        = string
  description = "ID del recurso de la Private DNS Zone para Databricks (ej. privatelink.azuredatabricks.net)."
}

# --- Variables para la Cuenta de Almacenamiento Opcional ---

variable "create_storage_account" {
  type        = bool
  description = "Si se establece en true, crea una cuenta de almacenamiento dedicada para Databricks."
  default     = false
}

variable "storage_account_name" {
  type        = string
  description = "Nombre único global para la cuenta de almacenamiento. Requerido si create_storage_account es true."
  default     = null
}

# --- Variable de Etiquetas ---

variable "tags" {
  type        = map(string)
  description = "Un mapa de etiquetas para aplicar a todos los recursos creados."
  default     = {}
}


