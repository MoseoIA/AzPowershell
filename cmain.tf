# --- main.tf en el proyecto CentroContactoDatos ---
# Este archivo define la infraestructura del proyecto llamando a módulos reutilizables.

# Define el proveedor de Azure y sus requerimientos.
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0" # Se recomienda fijar la versión.
    }
  }
}

provider "azurerm" {
  features {}
}

# --- DATA SOURCES ---
# Obtiene información de recursos existentes que son prerrequisitos.

# Obtiene la Private DNS Zone que es necesaria para el Private Endpoint de Databricks.
# Asegúrate de que esta zona ya exista en tu suscripción.
data "azurerm_private_dns_zone" "databricks_dns" {
  name                = "privatelink.azuredatabricks.net"
  resource_group_name = "z-nsm-ccint-pp01-ue2-01" 
}

# --- LLAMADA AL MÓDULO DE DATABRICKS ---
# Aquí se consume el módulo del repositorio AzNativeServices.
module "databricks_contact_center" {
  # IMPORTANTE: Reemplaza la URL con la de tu repositorio de GitHub.
  # El uso de `?ref=v1.2.0` (o la versión que corresponda) es una buena práctica.
  source = "git::https://github.com/tu-organizacion/AzNativeServices.git//Mod_AzDatabricks_Native?ref=v1.2.0"

  # Asignación de valores a las variables del módulo.
  resource_group_name            = "z-nsm-contactcenter-pp01-ue2-01"
  workspace_name                 = "dbrk-contactcenter-pp01-ue2-01"
  managed_resource_group_name    = "z-nsm-contactcenter-pp01-ue2-01-dbmng"
  
  databricks_vnet_name           = "znsmccentercintpp01eu2net01"
  databricks_vnet_rg_name        = "z-nsm-ccentercint-pp01-ue2-01"
  databricks_public_subnet_name  = "databrickspub64-pic-rt"
  databricks_private_subnet_name = "databrickspriv64-pic-rt"

  private_endpoint_vnet_name     = "znsmccintpp01ue2net01"
  private_endpoint_vnet_rg_name  = "z-nsm-ccint-pp01-ue2-01"
  private_endpoint_subnet_name   = "main-pic-rt"
  
  private_dns_zone_id_databricks = data.azurerm_private_dns_zone.databricks_dns.id

  # --- Habilitar creación de la cuenta de almacenamiento ---
  create_storage_account = true
  # NOTA: El nombre debe ser único globalmente y solo minúsculas y números.
  storage_account_name   = "stcontactcenterpp01ue2"

  tags = {
    Proyecto = "CentroContactoDatos"
    Ambiente = "Piloto-Produccion"
    Owner    = "EquipoDeDatos"
  }
}

