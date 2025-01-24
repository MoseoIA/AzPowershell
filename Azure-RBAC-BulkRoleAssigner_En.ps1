# -----------------------------------------------
# Configuración Inicial (¡Modifica estos valores!)
# -----------------------------------------------

# 1. Lista de grupos de recursos (ej: "RG-Prod", "RG-Dev")
$gruposRecursos = @("NombreGrupoRecurso1", "NombreGrupoRecurso2")

# 2. Lista de grupos de seguridad (ej: "SG-Admins", "SG-Developers")
$gruposSeguridad = @("NombreGrupoSeguridad1", "NombreGrupoSeguridad2")

# 3. Lista de Service Principals (IDs o Nombres)
$servicePrincipals = @("00000000-0000-0000-0000-000000000000", "NombreSP")

# 4. Roles a asignar (SOLO Lectura y Colaboración)
$rolesPermitidos = @("Reader", "Contributor")

# -----------------------------------------------
# Selección de Suscripción
# -----------------------------------------------
Write-Host "`n🔍 Listando suscripciones disponibles..." -ForegroundColor Cyan
$suscripciones = Get-AzSubscription
$suscripciones | ForEach-Object { Write-Host "📜 $($_.Name) (ID: $($_.Id))" }

# Solicitar al usuario que ingrese el nombre de la suscripción
$nombreSuscripcion = Read-Host "`n🔑 Ingresa el nombre de la suscripción donde deseas trabajar"

# Cambiar el contexto a la suscripción seleccionada
$suscripcion = $suscripciones | Where-Object { $_.Name -eq $nombreSuscripcion }
if ($suscripcion) {
    Set-AzContext -SubscriptionId $suscripcion.Id
    Write-Host "✅ Contexto cambiado a la suscripción: '$nombreSuscripcion'." -ForegroundColor Green
}
else {
    Write-Host "❌ No se encontró la suscripción '$nombreSuscripcion'. Verifica el nombre e intenta nuevamente." -ForegroundColor Red
    exit
}

# -----------------------------------------------
# Asignación de Roles
# -----------------------------------------------
foreach ($grupoRecurso in $gruposRecursos) {
    $grupoRecursoObj = Get-AzResourceGroup -Name $grupoRecurso -ErrorAction SilentlyContinue
    if (-not $grupoRecursoObj) {
        Write-Host "❌ Grupo de recursos '$grupoRecurso' no encontrado." -ForegroundColor Red
        continue
    }

    # Asignar roles a grupos de seguridad
    foreach ($grupoSeguridad in $gruposSeguridad) {
        $grupoSeguridadObj = Get-AzADGroup -DisplayName $grupoSeguridad -ErrorAction SilentlyContinue
        if ($grupoSeguridadObj) {
            foreach ($rol in $rolesPermitidos) {
                New-AzRoleAssignment -ObjectId $grupoSeguridadObj.Id -RoleDefinitionName $rol -Scope $grupoRecursoObj.ResourceId
                Write-Host "✅ Rol '$rol' asignado al grupo de seguridad '$grupoSeguridad' en '$grupoRecurso'." -ForegroundColor Green
            }
        }
        else {
            Write-Host "❌ Grupo de seguridad '$grupoSeguridad' no encontrado." -ForegroundColor Red
        }
    }

    # Asignar roles a Service Principals
    foreach ($sp in $servicePrincipals) {
        $servicePrincipalObj = Get-AzADServicePrincipal -ObjectId $sp -ErrorAction SilentlyContinue
        if (-not $servicePrincipalObj) {
            $servicePrincipalObj = Get-AzADServicePrincipal -DisplayName $sp -ErrorAction SilentlyContinue
        }
        if ($servicePrincipalObj) {
            foreach ($rol in $rolesPermitidos) {
                New-AzRoleAssignment -ObjectId $servicePrincipalObj.Id -RoleDefinitionName $rol -Scope $grupoRecursoObj.ResourceId
                Write-Host "✅ Rol '$rol' asignado al Service Principal '$($servicePrincipalObj.DisplayName)' en '$grupoRecurso'." -ForegroundColor Green
            }
        }
        else {
            Write-Host "❌ Service Principal '$sp' no encontrado." -ForegroundColor Red
        }
    }
}

Write-Host "`n🚀 Proceso completado en la suscripción '$nombreSuscripcion'." -ForegroundColor Cyan
