# Repositorio de Scripts de Automatización para Azure con PowerShell

Este repositorio es una colección centralizada de scripts de PowerShell diseñados para automatizar tareas de administración, gobierno y generación de informes en entornos de Microsoft Azure.

## Propósito

El objetivo de este repositorio es proporcionar un conjunto de herramientas de automatización robustas y reutilizables que ayuden a los administradores y desarrolladores de Azure a:

-   **Optimizar Tareas Repetitivas**: Automatizar la gestión de usuarios, grupos, permisos y otros recursos.
-   **Aplicar Gobierno y Cumplimiento**: Implementar y auditar políticas de etiquetado, configuraciones de seguridad y otros estándares de gobierno.
-   **Generar Informes**: Extraer información valiosa sobre el estado y la configuración de los recursos de Azure.
-   **Simplificar Operaciones Complejas**: Proveer scripts para tareas que requieren múltiples pasos o lógica avanzada.

## Estructura del Repositorio

Los scripts están organizados en carpetas funcionales para facilitar su localización y mantenimiento:

```
.
├── Identity-Access-Management/
├── Governance/
├── Reporting/
├── Utilities/
└── Service-Specific/
    └── Databricks/
```

-   **`/Identity-Access-Management`**: Contiene scripts relacionados con la gestión de identidades y accesos en Azure Active Directory (Azure AD) y Azure RBAC. Ejemplos:
    -   Asignación masiva de roles.
    -   Gestión de propietarios de grupos.
    -   Informes de estado de MFA de usuarios.

-   **`/Governance`**: Scripts para aplicar y auditar políticas de gobierno en Azure.
    -   Aplicación y validación de etiquetas (tags).
    -   Auditoría de configuraciones de recursos.

-   **`/Reporting`**: Scripts cuyo propósito principal es generar informes sobre el estado de los recursos de Azure.

-   **`/Utilities`**: Herramientas y scripts de propósito general que sirven como utilidades para otras tareas.
    -   Generación de CSR (Certificate Signing Requests).

-   **`/Service-Specific`**: Scripts que son específicos para la automatización o gestión de un servicio de Azure en particular.
    -   **`/Databricks`**: Scripts para interactuar o gestionar workspaces de Azure Databricks.

## Requisitos Previos

Para utilizar estos scripts, generalmente necesitarás:

1.  **PowerShell 7.x** o superior.
2.  El módulo de PowerShell de Azure (`Az`). Puedes instalarlo con el siguiente comando:
    ```powershell
    Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
    ```
3.  Conexión a tu tenant de Azure. Antes de ejecutar la mayoría de los scripts, deberás autenticarte:
    ```powershell
    Connect-AzAccount
    ```

## Cómo Utilizar los Scripts

1.  Navega a la carpeta correspondiente a la tarea que deseas realizar.
2.  Lee los comentarios o la documentación dentro del script para entender su propósito, los parámetros que acepta y los permisos que requiere.
3.  Ejecuta el script desde una terminal de PowerShell, proporcionando los parámetros necesarios.

**Ejemplo:**

```powershell
.\Governance\ApplyAzureTags.ps1 -ResourceGroupName "my-resource-group" -Tags @{ "Environment"="Production"; "Owner"="Admin" }
```

## Contribuciones

Las contribuciones a este repositorio son bienvenidas. Si tienes un script que crees que podría ser útil, por favor, sigue la estructura de carpetas existente y documenta claramente el propósito y uso del script.
