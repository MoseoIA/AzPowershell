# -----------------------------------------------
# Initial Configuration (Modify these values!)
# -----------------------------------------------

# 1. Subscription Name (Define the subscription name here)
$subscriptionName = "Dev-Subscription" # Replace with your subscription name

# 2. List of resource groups (e.g., "RG-Prod", "RG-Dev")
$resourceGroups = @("ResourceGroup1", "ResourceGroup2")

# 3. List of security groups (e.g., "SG-Admins", "SG-Developers")
$securityGroups = @("SecurityGroup1", "SecurityGroup2")

# 4. List of Service Principals (IDs or Names)
$servicePrincipals = @("00000000-0000-0000-0000-000000000000", "ServicePrincipalName")

# 5. List of specific resources (e.g., VM, Storage Account)
# Note: Resource type is optional. If not provided, the script will search by name only.
$specificResources = @(
    @{ Name = "MyVM" }, # No type specified
    @{ Name = "MyStorageAccount"; Type = "Microsoft.Storage/storageAccounts" } # Type specified
)

# 6. Roles to assign (ONLY Reader and Contributor)
$allowedRoles = @("Reader", "Contributor")

# -----------------------------------------------
# Set Subscription Context
# -----------------------------------------------
$subscription = Get-AzSubscription -SubscriptionName $subscriptionName -ErrorAction SilentlyContinue
if ($subscription) {
    Set-AzContext -SubscriptionId $subscription.Id
    Write-Host "✅ Context changed to subscription: '$subscriptionName'." -ForegroundColor Green
}
else {
    Write-Host "❌ Subscription '$subscriptionName' not found. Please verify the name and try again." -ForegroundColor Red
    exit
}

# -----------------------------------------------
# Role Assignment
# -----------------------------------------------

# Function to assign roles
function Assign-Role {
    param (
        [string]$ObjectId,
        [string]$Role,
        [string]$Scope
    )
    New-AzRoleAssignment -ObjectId $ObjectId -RoleDefinitionName $Role -Scope $Scope
    Write-Host "✅ Role '$Role' assigned to object '$ObjectId' at scope '$Scope'." -ForegroundColor Green
}

# Assign roles to resource groups
foreach ($resourceGroup in $resourceGroups) {
    $resourceGroupObj = Get-AzResourceGroup -Name $resourceGroup -ErrorAction SilentlyContinue
    if (-not $resourceGroupObj) {
        Write-Host "❌ Resource group '$resourceGroup' not found." -ForegroundColor Red
        continue
    }

    # Assign roles to security groups
    foreach ($securityGroup in $securityGroups) {
        $securityGroupObj = Get-AzADGroup -DisplayName $securityGroup -ErrorAction SilentlyContinue
        if ($securityGroupObj) {
            foreach ($role in $allowedRoles) {
                Assign-Role -ObjectId $securityGroupObj.Id -Role $role -Scope $resourceGroupObj.ResourceId
            }
        }
        else {
            Write-Host "❌ Security group '$securityGroup' not found." -ForegroundColor Red
        }
    }

    # Assign roles to Service Principals
    foreach ($sp in $servicePrincipals) {
        $servicePrincipalObj = Get-AzADServicePrincipal -ObjectId $sp -ErrorAction SilentlyContinue
        if (-not $servicePrincipalObj) {
            $servicePrincipalObj = Get-AzADServicePrincipal -DisplayName $sp -ErrorAction SilentlyContinue
        }
        if ($servicePrincipalObj) {
            foreach ($role in $allowedRoles) {
                Assign-Role -ObjectId $servicePrincipalObj.Id -Role $role -Scope $resourceGroupObj.ResourceId
            }
        }
        else {
            Write-Host "❌ Service Principal '$sp' not found." -ForegroundColor Red
        }
    }
}

# Assign roles to specific resources
foreach ($resource in $specificResources) {
    if ($resource.Type) {
        # Search by name and type
        $resourceObj = Get-AzResource -Name $resource.Name -ResourceType $resource.Type -ErrorAction SilentlyContinue
    }
    else {
        # Search by name only
        $resourceObj = Get-AzResource -Name $resource.Name -ErrorAction SilentlyContinue
    }

    if (-not $resourceObj) {
        Write-Host "❌ Resource '$($resource.Name)' not found." -ForegroundColor Red
        continue
    }

    # Assign roles to security groups
    foreach ($securityGroup in $securityGroups) {
        $securityGroupObj = Get-AzADGroup -DisplayName $securityGroup -ErrorAction SilentlyContinue
        if ($securityGroupObj) {
            foreach ($role in $allowedRoles) {
                Assign-Role -ObjectId $securityGroupObj.Id -Role $role -Scope $resourceObj.ResourceId
            }
        }
        else {
            Write-Host "❌ Security group '$securityGroup' not found." -ForegroundColor Red
        }
    }

    # Assign roles to Service Principals
    foreach ($sp in $servicePrincipals) {
        $servicePrincipalObj = Get-AzADServicePrincipal -ObjectId $sp -ErrorAction SilentlyContinue
        if (-not $servicePrincipalObj) {
            $servicePrincipalObj = Get-AzADServicePrincipal -DisplayName $sp -ErrorAction SilentlyContinue
        }
        if ($servicePrincipalObj) {
            foreach ($role in $allowedRoles) {
                Assign-Role -ObjectId $servicePrincipalObj.Id -Role $role -Scope $resourceObj.ResourceId
            }
        }
        else {
            Write-Host "❌ Service Principal '$sp' not found." -ForegroundColor Red
        }
    }
}

Write-Host "`n🚀 Process completed in subscription '$subscriptionName'." -ForegroundColor Cyan
