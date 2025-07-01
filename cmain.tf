# --- main.tf en el proyecto CentroContactoDatos ---

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# --- Data Sources ---
# Es una buena práctica obtener los IDs de forma dinámica.
# Aquí obtenemos la Private DNS Zone que es necesaria para el Private Endpoint.
# Asegúrate de que esta zona ya exista.
data "azurerm_private_dns_zone" "databricks_dns" {
  name                = "privatelink.azuredatabricks.net"
  # Asumo que la zona DNS vive en el mismo RG que la VNet del PE. Ajusta si es necesario.
  resource_group_name = "z-nsm-ccint-pp01-ue2-01" 
}


# --- Llamada al Módulo de Databricks ---
module "databricks_contact_center" {
  # IMPORTANTE: Reemplaza la URL con la de tu repositorio de GitHub.
  # El uso de `?ref=v1.0.0` permite anclar una versión específica del módulo.
  source = "git::https://github.com/tu-organizacion/AzNativeServices.git//Mod_AzDatabricks_Native?ref=v1.0.0"

  # Asignación de valores a las variables del módulo con tus nombres específicos.
  resource_group_name           = "z-nsm-contactcenter-pp01-ue2-01"
  workspace_name                = "dbrk-contactcenter-pp01-ue2-01" # Nombre sugerido
  managed_resource_group_name   = "z-nsm-contactcenter-pp01-ue2-01-dbmng"
  
  databricks_vnet_name          = "znsmccentercintpp01eu2net01"
  databricks_vnet_rg_name       = "z-nsm-ccentercint-pp01-ue2-01"
  databricks_public_subnet_name = "databrickspub64-pic-rt"
  # NOTA: El nombre de la subnet privada era igual a la pública en tu solicitud. 
  # He asumido que es un error tipográfico y lo he corregido. Por favor, verifica el nombre correcto.
  databricks_private_subnet_name = "databrickspriv64-pic-rt" 

  private_endpoint_vnet_name    = "znsmccintpp01ue2net01"
  private_endpoint_vnet_rg_name = "z-nsm-ccint-pp01-ue2-01"
  private_endpoint_subnet_name  = "main-pic-rt"
  
  private_dns_zone_id_databricks = data.azurerm_private_dns_zone.databricks_dns.id

  tags = {
    Proyecto = "CentroContactoDatos"
    Ambiente = "Piloto-Produccion"
    Owner    = "EquipoDeDatos"
  }
}

# --- Salidas del Proyecto ---
# Muestra información útil después de aplicar los cambios.
output "url_databricks_centro_contacto" {
  value       = module.databricks_contact_center.databricks_workspace_url
  description = "URL de acceso al workspace de Databricks para el Centro de Contacto."
}
