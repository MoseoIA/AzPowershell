### Script de ejemplo para asignar roles de Reader y Contributor en varios grupos de recursos ###

# Iniciar sesión en Azure (si no lo has hecho ya):
# Connect-AzAccount

# 1. Lista de nombres de los Grupos de Recursos a los que se les asignarán roles
$resourceGroupNames = @(
    "NombreRG1",
    "NombreRG2",
    "NombreRG3"
)

# 2. Lista de IDs de objeto (ObjectID) de los grupos de seguridad o service principals
#    a los que se asignarán los roles
#    (Puedes obtener el ObjectID de un grupo o de una app/service principal 
#     usando el Azure Portal o comandos como Get-AzADGroup, Get-AzADServicePrincipal, etc.)
$principalObjectIds = @(
    "00000000-0000-0000-0000-000000000001",
    "00000000-0000-0000-0000-000000000002"
)

# 3. Asignar roles en cada grupo de recursos
foreach ($rgName in $resourceGroupNames) {

    # Obtener el objeto del Grupo de Recursos
    $rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue

    if ($null -eq $rg) {
        Write-Host "El grupo de recursos '$rgName' no existe o no se pudo obtener."
        continue
    }

    # Obtener el Resource ID del grupo de recursos para usarlo como Scope
    $resourceGroupId = $rg.ResourceId

    # Asignar roles a cada principal (grupo de seguridad o service principal)
    foreach ($principalId in $principalObjectIds) {
        
        Write-Host "Asignando roles a principal con ObjectID: $principalId en RG: $rgName"

        try {
            # Asignar Rol de Lector (Reader)
            New-AzRoleAssignment `
                -ObjectId $principalId `
                -RoleDefinitionName "Reader" `
                -Scope $resourceGroupId `
                -ErrorAction Stop

            # Asignar Rol de Colaborador (Contributor)
            New-AzRoleAssignment `
                -ObjectId $principalId `
                -RoleDefinitionName "Contributor" `
                -Scope $resourceGroupId `
                -ErrorAction Stop
        }
        catch {
            Write-Host "Error asignando roles a $principalId en grupo de recursos $rgName:`n$($_.Exception.Message)"
        }
    }
}