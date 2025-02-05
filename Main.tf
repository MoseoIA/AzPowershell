# Crear el grupo de recursos
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Crear la cuenta de almacenamiento
resource "azurerm_storage_account" "storage" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Asegúrate de que el tipo de cuenta sea compatible con Logic Apps Standard
  account_kind             = "StorageV2"
}

# Crear el App Service Plan (para Logic App Standard)
resource "azurerm_service_plan" "app_service_plan" {
  name                = "logic-app-service-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"  # Logic Apps Standard requiere Linux
  sku_name            = "WS1"    # Tamaño del plan (WS1, WS2, WS3)

  # El tipo de plan debe ser "WorkflowStandard" para Logic Apps Standard
  kind                = "elastic"
}

# Crear la Logic App en modo Standard
resource "azurerm_logic_app_standard" "logic_app_standard" {
  name                       = var.logic_app_name
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  service_plan_id            = azurerm_service_plan.app_service_plan.id
  storage_account_name       = azurerm_storage_account.storage.name
  storage_account_access_key = azurerm_storage_account.storage.primary_access_key

  app_settings = {
    "WEBSITE_CONTENTAZUREFILECONNECTIONSTRING" = "DefaultEndpointsProtocol=https;AccountName=${azurerm_storage_account.storage.name};AccountKey=${azurerm_storage_account.storage.primary_access_key};EndpointSuffix=core.windows.net"
    "WEBSITE_CONTENTSHARE"                     = "${var.logic_app_name}-content"
  }

  site_config {
    always_on = true
  }

  tags = {
    environment = var.environment
  }
}
