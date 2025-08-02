# -----------------------------------------------
# Configuración inicial (¡Modifica estos valores!)
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
    $rg = Get-AzResourceGroup -Name $grupoRecurso -ErrorAction SilentlyContinue
    if (-not $rg) {
        Write-Host "❌ Grupo de recursos '$grupoRecurso' no encontrado." -ForegroundColor Red
        continue
    }

    # Asignar roles a grupos de seguridad
    foreach ($grupoSeguridad in $gruposSeguridad) {
        $sg = Get-AzADGroup -DisplayName $grupoSeguridad -ErrorAction SilentlyContinue
        if ($sg) {
            foreach ($rol in $rolesPermitidos) {
                New-AzRoleAssignment -ObjectId $sg.Id -RoleDefinitionName $rol -Scope $rg.ResourceId
                Write-Host "✅ Rol '$rol' asignado al grupo de seguridad '$grupoSeguridad' en '$grupoRecurso'." -ForegroundColor Green
            }
        }
        else {
            Write-Host "❌ Grupo de seguridad '$grupoSeguridad' no encontrado." -ForegroundColor Red
        }
    }

    # Asignar roles a Service Principals
    foreach ($sp in $servicePrincipals) {
        $servicePrincipal = Get-AzADServicePrincipal -ObjectId $sp -ErrorAction SilentlyContinue
        if (-not $servicePrincipal) {
            $servicePrincipal = Get-AzADServicePrincipal -DisplayName $sp -ErrorAction SilentlyContinue
        }
        if ($servicePrincipal) {
            foreach ($rol in $rolesPermitidos) {
                New-AzRoleAssignment -ObjectId $servicePrincipal.Id -RoleDefinitionName $rol -Scope $rg.ResourceId
                Write-Host "✅ Rol '$rol' asignado al Service Principal '$($servicePrincipal.DisplayName)' en '$grupoRecurso'." -ForegroundColor Green
            }
        }
        else {
            Write-Host "❌ Service Principal '$sp' no encontrado." -ForegroundColor Red
        }
    }
}

Write-Host "`n🚀 Proceso completado en la suscripción '$nombreSuscripcion'." -ForegroundColor Cyan
