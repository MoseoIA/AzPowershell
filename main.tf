# --- main.tf en Mod_AzDatabricks_Native ---

# Obtiene datos del grupo de recursos existente donde vivirá Databricks.
data "azurerm_resource_group" "rg_databricks" {
  name = var.resource_group_name
}

# Obtiene datos de las subnets existentes para la inyección de VNet en Databricks.
data "azurerm_subnet" "databricks_public_subnet" {
  name                 = var.databricks_public_subnet_name
  virtual_network_name = var.databricks_vnet_name
  resource_group_name  = var.databricks_vnet_rg_name
}

data "azurerm_subnet" "databricks_private_subnet" {
  name                 = var.databricks_private_subnet_name
  virtual_network_name = var.databricks_vnet_name
  resource_group_name  = var.databricks_vnet_rg_name
}

# Obtiene datos de la subnet existente para el Private Endpoint.
data "azurerm_subnet" "private_endpoint_subnet" {
  name                 = var.private_endpoint_subnet_name
  virtual_network_name = var.private_endpoint_vnet_name
  resource_group_name  = var.private_endpoint_vnet_rg_name
}

# --- Creación del Workspace de Azure Databricks ---
# Este recurso despliega el workspace con la configuración de red segura.
resource "azurerm_databricks_workspace" "databricks_ws" {
  name                          = var.workspace_name
  resource_group_name           = data.azurerm_resource_group.rg_databricks.name
  location                      = data.azurerm_resource_group.rg_databricks.location
  sku                           = var.sku
  managed_resource_group_name   = var.managed_resource_group_name
  public_network_access_enabled = false # Clave para deshabilitar el acceso público.

  # Parámetros personalizados para la inyección en la VNet.
  custom_parameters {
    no_public_ip                               = true # No asigna IPs públicas a los nodos del clúster.
    public_subnet_name                         = data.azurerm_subnet.databricks_public_subnet.name
    private_subnet_name                        = data.azurerm_subnet.databricks_private_subnet.name
    virtual_network_id                         = data.azurerm_subnet.databricks_public_subnet.virtual_network_id
  }

  tags = var.tags
}

# --- Creación del Private Endpoint ---
# Este recurso asegura que el acceso al workspace sea únicamente a través de tu red privada.
resource "azurerm_private_endpoint" "databricks_pe" {
  name                = "${var.workspace_name}-pe"
  resource_group_name = data.azurerm_resource_group.rg_databricks.name
  location            = data.azurerm_resource_group.rg_databricks.location
  subnet_id           = data.azurerm_subnet.private_endpoint_subnet.id

  # Conexión al servicio de Databricks.
  private_service_connection {
    name                           = "${var.workspace_name}-psc"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_databricks_workspace.databricks_ws.id
    # El sub-recurso "databricks_ui_api" es específico para el workspace.
    subresource_names              = ["databricks_ui_api"]
  }

  # Integración con DNS privado para la resolución de nombres.
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.private_dns_zone_id_databricks]
  }

  tags = var.tags
}
