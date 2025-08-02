# EXPERT MODE - Rewritten for robustness, safety, and workflow integration.
param(
    [Parameter(Mandatory = $true, HelpMessage = "A comma-separated string of tags to apply. Format: 'tagKey1=tagValue1,tagKey2=tagValue2'.")]
    [string]$TagsToApply,

    [Parameter(Mandatory = $false, HelpMessage = "Path to a CSV file containing resources to tag. Must contain a 'ResourceId' column.")]
    [string]$InputCSV,

    [Parameter(Mandatory = $false, HelpMessage = "For ad-hoc use without a CSV. Defines the scope to apply tags to.")]
    [ValidateSet("ResourceGroups", "Resources")]
    [string]$TargetType,

    [Parameter(Mandatory = $false, HelpMessage = "An action to determine how tags are applied.")]
    [ValidateSet("Merge", "Replace", "Add")]
    [string]$TagAction = "Merge",

    [Parameter(Mandatory = $false, HelpMessage = "Optional: Filter resources by a specific resource group name (supports wildcards).")]
    [string]$ResourceGroupFilter,

    [Parameter(Mandatory = $false, HelpMessage = "Switch to simulate the operation. No actual changes will be made.")]
    [switch]$WhatIf,

    [Parameter(Mandatory = $false, HelpMessage = "Specify a full path for the detailed operation log CSV file.")]
    [string]$LogPath
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

function Parse-TagsToApply {
    param([string]$TagsString)
    $tagsHash = @{}
    try {
        $tagPairs = $TagsString -split ','
        foreach ($tagPair in $tagPairs) {
            if ($tagPair -match '=(.+)') {
                $key, $value = $tagPair.Split('=', 2).Trim()
                if ($key) { $tagsHash[$key] = $value }
            }
        }
        if ($tagsHash.Count -eq 0) { throw "No valid tags were parsed." }
        return $tagsHash
    } catch {
        Write-Host "Error parsing tags to apply: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Get-TargetResources {
    param([string]$Type, [string]$RGFilter)

    Write-Host "Fetching target resources from Azure..." -ForegroundColor Yellow
    $resources = @()
    if ($Type -eq 'ResourceGroups' -or -not $Type) {
        $resources += Get-AzResourceGroup | Where-Object { -not $RGFilter -or $_.ResourceGroupName -like $RGFilter }
    }
    if ($Type -eq 'Resources' -or -not $Type) {
        $resources += Get-AzResource | Where-Object { -not $RGFilter -or $_.ResourceGroupName -like $RGFilter }
    }
    Write-Host "Found $($resources.Count) resources to process." -ForegroundColor Green
    return $resources
}

function Invoke-TagRemediation {
    param(
        [Parameter(Mandatory=$true)]
        [psobject]$Resource,
        [Parameter(Mandatory=$true)]
        [hashtable]$Tags,
        [Parameter(Mandatory=$true)]
        [string]$Action,
        [Parameter(Mandatory=$true)]
        [switch]$IsWhatIf
    )

    $currentTags = $Resource.Tags
    $newTags = switch ($Action) {
        "Replace" { $Tags }
        "Add"     { $currentTags + $Tags }
        default   { $currentTags.GetEnumerator() | ForEach-Object { $Tags[$_.Name] = $_.Value }; $Tags }
    }

    $result = [PSCustomObject]@{
        ResourceId    = $Resource.ResourceId
        Name          = $Resource.Name
        ResourceType  = $Resource.ResourceType
        Status        = ""
        Action        = $Action
        OldTags       = ($currentTags.GetEnumerator() | ForEach-Object {"$($_.Key)=$($_.Value)"}) -join "; "
        NewTags       = ($newTags.GetEnumerator() | ForEach-Object {"$($_.Key)=$($_.Value)"}) -join "; "
        Message       = ""
    }

    if ($IsWhatIf) {
        $result.Status = "Simulated"
        $result.Message = "WHAT-IF: Tags would be updated."
        return $result
    }

    try {
        $updateParams = @{ Tag = $newTags; ErrorAction = 'Stop' }
        if ($Resource.ResourceId) {
            $updateParams.ResourceId = $Resource.ResourceId
            Set-AzResource @updateParams -Force
        } else { # Fallback for older objects without ResourceId
            $updateParams.Name = $Resource.Name
            Set-AzResourceGroup @updateParams
        }
        $result.Status = "Success"
        $result.Message = "Tags applied successfully."
    } catch {
        $result.Status = "Failed"
        $result.Message = $_.Exception.Message
    }
    return $result
}

#endregion

# --- Main Script Execution ---
Write-Host "🚀 Starting Azure Tag Remediation Script..." -ForegroundColor Cyan

if (-not (Test-AzureConnection)) { exit 1 }

$tagsToApplyHash = Parse-TagsToApply -TagsString $TagsToApply
if (-not $tagsToApplyHash) { exit 1 }

$resourcesToProcess = @()
if ($InputCSV) {
    if (-not (Test-Path $InputCSV)) { Write-Host "Input CSV not found at path: $InputCSV" -ForegroundColor Red; exit 1 }
    Write-Host "Reading resources from CSV: $InputCSV" -ForegroundColor Yellow
    $resourcesToProcess = Import-Csv -Path $InputCSV
} elseif ($TargetType) {
    $resourcesToProcess = Get-TargetResources -Type $TargetType -RGFilter $ResourceGroupFilter
} else {
    Write-Host "You must specify either -InputCSV or -TargetType." -ForegroundColor Red
    exit 1
}

if ($resourcesToProcess.Count -eq 0) {
    Write-Host "No resources found to process." -ForegroundColor Yellow
    exit 0
}

Write-Host "`nApplying tags to $($resourcesToProcess.Count) resources. Action: $TagAction" -ForegroundColor Cyan
if ($WhatIf) {
    Write-Host "Running in SIMULATION mode (-WhatIf). No changes will be made." -ForegroundColor Yellow
} else {
    Read-Host -Prompt "`n⚠️ WARNING: You are about to modify tags on $($resourcesToProcess.Count) Azure resources. Press Enter to continue or CTRL+C to cancel."
}

$operationResults = @()
$i = 0
foreach ($resource in $resourcesToProcess) {
    $i++
    Write-Progress -Activity "Applying Tags" -Status "Processing resource $i of $($resourcesToProcess.Count): $($resource.Name)" -PercentComplete (($i / $resourcesToProcess.Count) * 100)
    
    # Get the full resource object if we only have the ID from a CSV
    $fullResource = Get-AzResource -ResourceId $resource.ResourceId -ErrorAction SilentlyContinue
    if (-not $fullResource) {
        $fullResource = Get-AzResourceGroup -Name $resource.Name -ErrorAction SilentlyContinue
    }

    if ($fullResource) {
        $operationResults += Invoke-TagRemediation -Resource $fullResource -Tags $tagsToApplyHash -Action $TagAction -IsWhatIf $WhatIf
    } else {
        $operationResults += [PSCustomObject]@{ ResourceId=$resource.ResourceId; Name=$resource.Name; Status='Failed'; Message='Could not find resource in Azure.' }
    }
}

# --- Final Report ---
Write-Host "`n`n📊 Remediation Summary:" -ForegroundColor Cyan
$operationResults | Format-Table -Property Name, ResourceType, Status, Message -AutoSize

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$defaultLogFile = Join-Path -Path $PSScriptRoot -ChildPath "Azure_Tags_Remediation_Report_${timestamp}.csv"
$reportPath = if ([string]::IsNullOrEmpty($LogPath)) { $defaultLogFile } else { $LogPath }

$operationResults | Export-Csv -Path $reportPath -NoTypeInformation -Encoding UTF8
Write-Host "`n✅ Operation complete. A detailed report has been saved to:" -ForegroundColor Green
Write-Host $reportPath -ForegroundColor White
