output "logic_app_standard_id" {
  description = "The ID of the Logic App Standard."
  value       = azurerm_logic_app_standard.logic_app_standard.id
}

output "logic_app_standard_endpoint" {
  description = "The endpoint URL of the Logic App Standard."
  value       = azurerm_logic_app_standard.logic_app_standard.default_hostname
}

output "storage_account_name" {
  description = "The name of the storage account associated with the Logic App Standard."
  value       = azurerm_storage_account.storage.name
}
