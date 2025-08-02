# Asegúrate de tener el módulo MSOnline
Install-Module MSOnline -Force -AllowClobber

# Iniciar sesión
Connect-MsolService

# Obtener todos los usuarios
$users = Get-MsolUser -All

# Filtrar los que NO tienen MFA habilitado
$noMFA = $users | Where-Object { $_.StrongAuthenticationMethods.Count -eq 0 }

# Mostrar resultados
$noMFA | Select-Object UserPrincipalName, DisplayName, IsLicensed | Format-Table -AutoSize

# Exportar a CSV si lo deseas
$noMFA | Select-Object UserPrincipalName, DisplayName, IsLicensed | Export-Csv -Path "usuarios_sin_MFA.csv" -NoTypeInformation -Encoding UTF8
