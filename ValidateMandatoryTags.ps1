# EXPERT MODE - Rewritten for clarity, robustness, and improved output.
param(
    [Parameter(Mandatory = $true, HelpMessage = "A comma-separated string of mandatory tags. Format: 'tag1=value1,tag2=value2'.")]
    [string]$MandatoryTags,

    [Parameter(Mandatory = $true, HelpMessage = "Specify the type of audit: ResourceGroups, Resources, or Both.")]
    [ValidateSet("ResourceGroups", "Resources", "Both")]
    [string]$AuditType,

    [Parameter(Mandatory = $false, HelpMessage = "Optional: Specify a Subscription ID to audit. If not provided, the current context's subscription is used.")]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $false, HelpMessage = "Optional: Specify the full path for the CSV export file. If not provided, a default name will be generated.")]
    [string]$OutputPath,

    [Parameter(Mandatory = $false, HelpMessage = "Switch to enable exporting the results to a CSV file.")]
    [switch]$ExportToCSV,

    [Parameter(Mandatory = $false, HelpMessage = "Switch to validate tag values. If not used, only the presence of the tag key is checked.")]
    [switch]$ValidateValues,

    [Parameter(Mandatory = $false, HelpMessage = "Switch to report only items with missing tags, ignoring items that only have incorrect values.")]
    [switch]$OnlyMissingTags
)

#region Core Functions

function Test-AzureConnection {
    try {
        if (-not (Get-AzContext)) { throw "No active Azure session." }
        return $true
    } catch {
        Write-Host "No active Azure session found. Please run Connect-AzAccount first." -ForegroundColor Red
        return $false
    }
}

function Parse-MandatoryTags {
    param([string]$MandatoryTagsString)
    $mandatoryTagsHash = @{}
    try {
        $tagPairs = $MandatoryTagsString -split ','
        foreach ($tagPair in $tagPairs) {
            if ($tagPair -match '=(.+)') { # Ensure there is a value, even if empty
                $key, $value = $tagPair.Split('=', 2).Trim()
                if ($key) { $mandatoryTagsHash[$key] = $value }
            }
        }
        if ($mandatoryTagsHash.Count -eq 0) { throw "No valid tags were parsed." }
        return $mandatoryTagsHash
    } catch {
        Write-Host "Error parsing mandatory tags: $($_.Exception.Message) Check format." -ForegroundColor Red
        return $null
    }
}

function Test-ResourceCompliance {
    param(
        [hashtable]$ResourceTags,
        [hashtable]$MandatoryTags,
        [bool]$ShouldValidateValues
    )
    $missingTags = @()
    $incorrectValues = @()

    foreach ($key in $MandatoryTags.Keys) {
        if (-not $ResourceTags.ContainsKey($key)) {
            $missingTags += $key
        } elseif ($ShouldValidateValues -and $ResourceTags[$key] -ne $MandatoryTags[$key]) {
            $incorrectValues += [PSCustomObject]@{
                TagName       = $key
                ExpectedValue = $MandatoryTags[$key]
                ActualValue   = $ResourceTags[$key]
            }
        }
    }
    return [PSCustomObject]@{ IsCompliant = ($missingTags.Count -eq 0 -and $incorrectValues.Count -eq 0); MissingTags = $missingTags; IncorrectValues = $incorrectValues }
}

function Get-NonCompliantItems {
    param(
        [string]$SubscriptionName,
        [hashtable]$MandatoryTags,
        [bool]$ShouldValidateValues,
        [bool]$ShouldCheckOnlyMissingTags,
        [string]$ItemType # "ResourceGroups" or "Resources"
    )

    Write-Host "Validating mandatory tags for $ItemType..." -ForegroundColor Yellow
    $items = if ($ItemType -eq "ResourceGroups") { Get-AzResourceGroup } else { Get-AzResource }
    $nonCompliantItems = @()

    foreach ($item in $items) {
        $complianceResult = Test-ResourceCompliance -ResourceTags $item.Tags -MandatoryTags $MandatoryTags -ShouldValidateValues $ShouldValidateValues

        if (-not $complianceResult.IsCompliant) {
            if ($ShouldCheckOnlyMissingTags -and $complianceResult.MissingTags.Count -eq 0) {
                continue
            }

            $nonCompliantItems += [PSCustomObject]@{
                SubscriptionName  = $SubscriptionName
                ResourceGroupName = $item.ResourceGroupName
                Name              = if ($ItemType -eq 'ResourceGroups') { $item.ResourceGroupName } else { $item.Name }
                ResourceType      = $item.ResourceType
                Location          = $item.Location
                MissingTags       = ($complianceResult.MissingTags | Out-String).Trim() -replace '\s+', ', '
                IncorrectValues   = ($complianceResult.IncorrectValues | ForEach-Object { "$($_.TagName) (Expected: '$($_.ExpectedValue)', Actual: '$($_.ActualValue)')" } | Out-String).Trim() -replace '\s+', '; '
                CurrentTags       = ($item.Tags.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" } | Out-String).Trim() -replace '\s+', '; '
                ResourceId        = $item.ResourceId
            }
        }
    }
    return $nonCompliantItems
}

#endregion

#region Output Functions

function Export-ResultsToCSV {
    param([array]$Results, [string]$OutputPath, [string]$AuditType)

    if (-not $Results) {
        Write-Host "No non-compliant items to export." -ForegroundColor Yellow
        return
    }

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    if ([string]::IsNullOrEmpty($OutputPath)) {
        $OutputPath = Join-Path -Path $PSScriptRoot -ChildPath "Azure_Mandatory_Tags_Validation_${AuditType}_${timestamp}.csv"
    }

    $directory = Split-Path -Path $OutputPath -Parent
    if (-not (Test-Path $directory)) {
        try {
            New-Item -ItemType Directory -Path $directory -Force -ErrorAction Stop | Out-Null
        } catch {
            Write-Host "Error creating directory '$directory': $($_.Exception.Message)" -ForegroundColor Red
            return
        }
    }

    try {
        Write-Host "Exporting $($Results.Count) non-compliant items to CSV..." -ForegroundColor Yellow
        $Results | Select-Object SubscriptionName, ResourceGroupName, Name, ResourceType, Location, MissingTags, IncorrectValues, CurrentTags, ResourceId |
            Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8 -ErrorAction Stop
        Write-Host "✅ Results successfully exported to: $OutputPath" -ForegroundColor Green
    } catch {
        Write-Host "❌ Error exporting results: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Show-Results {
    param([array]$Results, [string]$Type)

    if (-not $Results) {
        Write-Host "✅ All audited $Type are compliant." -ForegroundColor Green
        return
    }

    Write-Host "`n⚠️ Found $($Results.Count) non-compliant ${Type}:" -ForegroundColor Yellow
    $Results | Format-Table -Property Name, ResourceType, ResourceGroupName, MissingTags, IncorrectValues -AutoSize
}

#endregion

# --- Main Script Execution ---
Write-Host "🚀 Starting Azure Mandatory Tag Validation..." -ForegroundColor Cyan

if (-not (Test-AzureConnection)) { exit 1 }

$mandatoryTagsHash = Parse-MandatoryTags -MandatoryTagsString $MandatoryTags
if (-not $mandatoryTagsHash) { exit 1 }

Write-Host "Auditing for mandatory tags: $($mandatoryTagsHash.Keys -join ', ')" -ForegroundColor Cyan

if ($SubscriptionId) { Set-AzContext -SubscriptionId $SubscriptionId -ErrorAction SilentlyContinue }

$currentContext = Get-AzContext

# Format connection context messages safely
$subscriptionMsg = "Auditing Subscription: '{0}' ({1})" -f $currentContext.Subscription.Name, $currentContext.Subscription.Id

Write-Host $subscriptionMsg -ForegroundColor Cyan

$subscriptionName = $currentContext.Subscription.Name

$allResults = @()
$commonParams = @{
    SubscriptionName         = $subscriptionName
    MandatoryTags            = $mandatoryTagsHash
    ShouldValidateValues     = $ValidateValues.IsPresent
    ShouldCheckOnlyMissingTags = $OnlyMissingTags.IsPresent
}

switch ($AuditType) {
    "ResourceGroups" {
        $results = Get-NonCompliantItems @commonParams -ItemType "ResourceGroups"
        Show-Results -Results $results -Type "Resource Groups"
        $allResults += $results
    }
    "Resources" {
        $results = Get-NonCompliantItems @commonParams -ItemType "Resources"
        Show-Results -Results $results -Type "Resources"
        $allResults += $results
    }
    "Both" {
        $rgResults = Get-NonCompliantItems @commonParams -ItemType "ResourceGroups"
        Show-Results -Results $rgResults -Type "Resource Groups"

        $resourceResults = Get-NonCompliantItems @commonParams -ItemType "Resources"
        Show-Results -Results $resourceResults -Type "Resources"

        if ($rgResults) { $allResults += $rgResults }
        if ($resourceResults) { $allResults += $resourceResults }
    }
}

if ($ExportToCSV) {
    Export-ResultsToCSV -Results $allResults -OutputPath $OutputPath -AuditType $AuditType
}

Write-Host "`n📊 Validation Summary:" -ForegroundColor Cyan
Write-Host "Total non-compliant items found: $($allResults.Count)" -ForegroundColor $(if ($allResults.Count -gt 0) { "Yellow" } else { "Green" })

Write-Host "`n✅ Validation complete." -ForegroundColor Green
