# -----------------------------------------------
# Initial Configuration (Modify these values!)
# -----------------------------------------------
$subscriptionName = "Dev-Subscription" # Replace with your subscription name
$resourceGroups = @("ResourceGroup1", "ResourceGroup2")
$securityGroups = @("SecurityGroup1", "SecurityGroup2")
$servicePrincipals = @("00000000-0000-0000-0000-000000000000", "ServicePrincipalName")
$specificResources = @(
    @{ Name = "MyVM" }, # No type specified
    @{ Name = "MyStorageAccount"; Type = "Microsoft.Storage/storageAccounts" } # Type specified
)
$allowedRoles = @("Reader", "Contributor")

# Log file for auditing (stored in the user's home directory in Cloud Shell)
$logFile = "/home/$env:USERNAME/AzureRoleAssignmentLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# -----------------------------------------------
# Helper Functions
# -----------------------------------------------
function Log-Message {
    param (
        [string]$Message,
        [string]$Level = "Info"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp [$Level] $Message"
    Add-Content -Path $logFile -Value $logEntry
    if ($Level -eq "Error") { Write-Host $logEntry -ForegroundColor Red }
    elseif ($Level -eq "Warning") { Write-Host $logEntry -ForegroundColor Yellow }
    else { Write-Host $logEntry -ForegroundColor Green }
}

function Get-AzureObject {
    param (
        [string]$Type,
        [string]$NameOrId
    )
    try {
        switch ($Type) {
            "Group" { return Get-AzADGroup -DisplayName $NameOrId -ErrorAction Stop }
            "ServicePrincipal" { 
                $obj = Get-AzADServicePrincipal -ObjectId $NameOrId -ErrorAction SilentlyContinue
                if (-not $obj) { $obj = Get-AzADServicePrincipal -DisplayName $NameOrId -ErrorAction Stop }
                return $obj
            }
            "Resource" { 
                if ($NameOrId.Contains("/")) {
                    return Get-AzResource -ResourceId $NameOrId -ErrorAction Stop
                }
                else {
                    return Get-AzResource -Name $NameOrId -ErrorAction Stop
                }
            }
            default { return $null }
        }
    }
    catch {
        Log-Message "Failed to retrieve Azure object of type '$Type' with name/id '$NameOrId': $_" -Level "Error"
        return $null
    }
}

function Assign-Role {
    param (
        [string]$ObjectId,
        [string]$Role,
        [string]$Scope
    )
    try {
        $existingAssignment = Get-AzRoleAssignment -ObjectId $ObjectId -RoleDefinitionName $Role -Scope $Scope -ErrorAction SilentlyContinue
        if (-not $existingAssignment) {
            New-AzRoleAssignment -ObjectId $ObjectId -RoleDefinitionName $Role -Scope $Scope -ErrorAction Stop
            Log-Message "Role '$Role' assigned to object '$ObjectId' at scope '$Scope'."
        }
        else {
            Log-Message "Role '$Role' is already assigned to object '$ObjectId' at scope '$Scope'." -Level "Warning"
        }
    }
    catch {
        Log-Message "Failed to assign role '$Role' to object '$ObjectId' at scope '$Scope': $_" -Level "Error"
    }
}

# -----------------------------------------------
# Validations
# -----------------------------------------------
$validRoles = @("Reader", "Contributor")
foreach ($role in $allowedRoles) {
    if ($role -notin $validRoles) {
        Log-Message "Invalid role '$role' specified. Only 'Reader' and 'Contributor' are allowed." -Level "Error"
        exit
    }
}

if (-not $resourceGroups -or -not $securityGroups -or -not $servicePrincipals) {
    Log-Message "One or more required lists (Resource Groups, Security Groups, Service Principals) are empty." -Level "Error"
    exit
}

# -----------------------------------------------
# Set Subscription Context
# -----------------------------------------------
try {
    $subscription = Get-AzSubscription -SubscriptionName $subscriptionName -ErrorAction Stop
    Set-AzContext -SubscriptionId $subscription.Id
    Log-Message "Context changed to subscription: '$subscriptionName'."
}
catch {
    Log-Message "Failed to set subscription context: $_" -Level "Error"
    exit
}

# -----------------------------------------------
# Interactive Menu
# -----------------------------------------------
# Step 1: Choose whether to assign permissions to Security Groups or Service Principals
Write-Host "`nSelect the target for role assignment:" -ForegroundColor Cyan
Write-Host "1. Security Groups"
Write-Host "2. Service Principals (SPN)"
$targetChoice = Read-Host "Enter your choice (1 or 2)"

switch ($targetChoice) {
    "1" { $targets = $securityGroups; $targetType = "Group" }
    "2" { $targets = $servicePrincipals; $targetType = "ServicePrincipal" }
    default {
        Log-Message "Invalid choice. Exiting script." -Level "Error"
        exit
    }
}

# Step 2: Choose whether to assign permissions to Resource Groups or Specific Resources
Write-Host "`nSelect the scope for role assignment:" -ForegroundColor Cyan
Write-Host "1. Resource Groups"
Write-Host "2. Specific Resources"
$scopeChoice = Read-Host "Enter your choice (1 or 2)"

switch ($scopeChoice) {
    "1" { $scopes = $resourceGroups; $scopeType = "ResourceGroup" }
    "2" { $scopes = $specificResources; $scopeType = "SpecificResource" }
    default {
        Log-Message "Invalid choice. Exiting script." -Level "Error"
        exit
    }
}

# -----------------------------------------------
# Role Assignment Logic
# -----------------------------------------------
foreach ($scope in $scopes) {
    $scopeObj = $null
    if ($scopeType -eq "ResourceGroup") {
        $scopeObj = Get-AzureObject -Type "Resource" -NameOrId $scope
    }
    elseif ($scopeType -eq "SpecificResource") {
        if ($scope.Type) {
            $scopeObj = Get-AzureObject -Type "Resource" -NameOrId $scope.Name
        }
        else {
            $scopeObj = Get-AzureObject -Type "Resource" -NameOrId $scope.Name
        }
    }

    if (-not $scopeObj) {
        Log-Message "Scope '$scope' not found." -Level "Error"
        continue
    }

    foreach ($target in $targets) {
        $targetObj = Get-AzureObject -Type $targetType -NameOrId $target
        if ($targetObj) {
            foreach ($role in $allowedRoles) {
                Assign-Role -ObjectId $targetObj.Id -Role $role -Scope $scopeObj.ResourceId
            }
        }
        else {
            Log-Message "$targetType '$target' not found." -Level "Error"
        }
    }
}

Log-Message "Process completed in subscription '$subscriptionName'." -Level "Info"
