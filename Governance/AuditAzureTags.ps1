# EXPERT MODE - Rewritten for clarity, robustness, and improved output.
param(
    [Parameter(Mandatory = $true, HelpMessage = "Specify the type of audit: ResourceGroups, Resources, or Both.")]
    [ValidateSet("ResourceGroups", "Resources", "Both")]
    [string]$AuditType,
    
    [Parameter(Mandatory = $false, HelpMessage = "Optional: Specify a Subscription ID to audit. If not provided, the current context's subscription is used.")]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory = $false, HelpMessage = "Optional: Specify the full path for the CSV export file. If not provided, a default name will be generated.")]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false, HelpMessage = "Switch to enable exporting the results to a CSV file.")]
    [switch]$ExportToCSV
)

#region Core Functions

# Function to check for an active Azure session.
function Test-AzureConnection {
    try {
        $context = Get-AzContext
        if ($null -eq $context) {
            Write-Host "No active Azure session found. Please run Connect-AzAccount first." -ForegroundColor Red
            return $false
        }
        return $true
    }
    catch {
        Write-Host "Error checking Azure connection: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to get resource groups without tags.
function Get-UntaggedResourceGroups {
    param(
        [string]$SubscriptionName
    )
    
    Write-Host "Fetching resource groups without tags..." -ForegroundColor Yellow
    try {
        $resourceGroups = Get-AzResourceGroup
        
        $untaggedGroups = foreach ($rg in $resourceGroups) {
            if ($null -eq $rg.Tags -or $rg.Tags.Count -eq 0) {
                # Output a unified object. For a Resource Group, its name is the resource itself.
                [PSCustomObject]@{
                    SubscriptionName  = $SubscriptionName
                    ResourceGroupName = $rg.ResourceGroupName
                    Name              = $rg.ResourceGroupName # The RG is the resource
                    ResourceType      = "Microsoft.Resources/subscriptions/resourceGroups"
                    Location          = $rg.Location
                    ResourceId        = $rg.ResourceId
                }
            }
        }
        return $untaggedGroups
    }
    catch {
        Write-Host "Error fetching resource groups: $($_.Exception.Message)" -ForegroundColor Red
        return @()
    }
}

# Function to get resources without tags.
function Get-UntaggedResources {
    param(
        [string]$SubscriptionName
    )
    
    Write-Host "Fetching resources without tags..." -ForegroundColor Yellow
    try {
        $resources = Get-AzResource
        
        $untaggedResources = foreach ($resource in $resources) {
            if ($null -eq $resource.Tags -or $resource.Tags.Count -eq 0) {
                # Output a unified object.
                [PSCustomObject]@{
                    SubscriptionName  = $SubscriptionName
                    ResourceGroupName = $resource.ResourceGroupName
                    Name              = $resource.Name
                    ResourceType      = $resource.ResourceType
                    Location          = $resource.Location
                    ResourceId        = $resource.ResourceId
                }
            }
        }
        return $untaggedResources
    }
    catch {
        Write-Host "Error fetching resources: $($_.Exception.Message)" -ForegroundColor Red
        return @()
    }
}

#endregion

#region Output Functions

# Function to export results to a CSV file.
function Export-ResultsToCSV {
    param(
        [array]$Results,
        [string]$OutputPath,
        [string]$AuditType
    )
    
    if (-not $Results) {
        Write-Host "No results to export." -ForegroundColor Yellow
        return
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    if ([string]::IsNullOrEmpty($OutputPath)) {
        # Generate a default, descriptive filename.
        $OutputPath = Join-Path -Path $PSScriptRoot -ChildPath "Azure_Tag_Audit_${AuditType}_${timestamp}.csv"
    }
    
    # Ensure the destination directory exists.
    $directory = Split-Path -Path $OutputPath -Parent
    if (-not (Test-Path $directory)) {
        try {
            New-Item -ItemType Directory -Path $directory -Force -ErrorAction Stop | Out-Null
            Write-Host "Created directory: $directory" -ForegroundColor Yellow
        }
        catch {
            Write-Host "Error creating directory '$directory': $($_.Exception.Message)" -ForegroundColor Red
            return
        }
    }
    
    try {
        Write-Host "Exporting $($Results.Count) results to CSV..." -ForegroundColor Yellow
        
        # Define the exact columns and order for the CSV.
        $Results | Select-Object SubscriptionName, ResourceGroupName, Name, ResourceType, Location, ResourceId |
            Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8 -ErrorAction Stop
            
        Write-Host "✅ Results successfully exported to: $OutputPath" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Error exporting results: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Function to display results in the console as a table.
function Show-Results {
    param(
        [array]$Results,
        [string]$Type
    )
    
    if (-not $Results) {
        Write-Host "✅ No untagged $Type found." -ForegroundColor Green
        return
    }
    
    Write-Host "`n⚠️ Found $($Results.Count) untagged ${Type}:" -ForegroundColor Yellow
    
    # Display results in a clean, formatted table.
    $Results | Format-Table -Property SubscriptionName, ResourceGroupName, Name, ResourceType, Location -AutoSize
}

#endregion

# --- Main Script Execution ---
Write-Host "🚀 Starting Azure Tag Audit..." -ForegroundColor Cyan
Write-Host "Audit Type: $AuditType" -ForegroundColor Cyan

if (-not (Test-AzureConnection)) {
    exit 1
}

# Set subscription context if specified.
if ($SubscriptionId) {
    Set-AzContext -SubscriptionId $SubscriptionId -ErrorAction SilentlyContinue
}

$currentContext = Get-AzContext

# Format connection context messages safely
$subscriptionMsg = "Auditing Subscription: '{0}' ({1})" -f $currentContext.Subscription.Name, $currentContext.Subscription.Id
$userMsg = "User Account: {0}" -f $currentContext.Account.Id

Write-Host $subscriptionMsg -ForegroundColor Cyan
Write-Host $userMsg -ForegroundColor Cyan

$subscriptionName = $currentContext.Subscription.Name
$allResults = @()

# Execute audit based on the specified type.
switch ($AuditType) {
    "ResourceGroups" {
        $results = Get-UntaggedResourceGroups -SubscriptionName $subscriptionName
        Show-Results -Results $results -Type "Resource Groups"
        $allResults += $results
    }
    "Resources" {
        $results = Get-UntaggedResources -SubscriptionName $subscriptionName
        Show-Results -Results $results -Type "Resources"
        $allResults += $results
    }
    "Both" {
        $rgResults = Get-UntaggedResourceGroups -SubscriptionName $subscriptionName
        Show-Results -Results $rgResults -Type "Resource Groups"
        
        $resourceResults = Get-UntaggedResources -SubscriptionName $subscriptionName
        Show-Results -Results $resourceResults -Type "Resources"
        
        if ($rgResults) { $allResults += $rgResults }
        if ($resourceResults) { $allResults += $resourceResults }
    }
}

# Export results if the switch is used.
if ($ExportToCSV) {
    Export-ResultsToCSV -Results $allResults -OutputPath $OutputPath -AuditType $AuditType
}

# Final summary.
$summaryColor = if ($allResults.Count -gt 0) { "Yellow" } else { "Green" }
Write-Host "`n📊 Audit Summary:" -ForegroundColor Cyan
Write-Host "Total untagged items found: $($allResults.Count)" -ForegroundColor $summaryColor

if ($allResults.Count -gt 0) {
    Write-Host "`n💡 Recommended Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Review the items listed in the table or CSV export."
    Write-Host "2. Use the 'ApplyAzureTags.ps1' script to remediate missing tags."
    Write-Host "3. Implement Azure Policy to enforce mandatory tagging for new resources."
}

Write-Host "`n✅ Audit complete." -ForegroundColor Green