# --- outputs.tf en Mod_AzDatabricks_Native ---

output "databricks_workspace_id" {
  value       = azurerm_databricks_workspace.databricks_ws.id
  description = "El ID del recurso del espacio de trabajo de Databricks."
}

output "databricks_workspace_url" {
  value       = azurerm_databricks_workspace.databricks_ws.workspace_url
  description = "La URL para acceder al espacio de trabajo de Databricks."
}

output "private_endpoint_id" {
  value       = azurerm_private_endpoint.databricks_pe.id
  description = "El ID del recurso del Private Endpoint creado para Databricks."
}
