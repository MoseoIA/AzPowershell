#Requires -Module AzureAD

<#
.SYNOPSIS
    Adds owners to Azure AD security groups from a CSV file.

.DESCRIPTION
    This script reads a CSV file with a group name and up to 5 owners and adds the specified owners to the corresponding Azure AD security groups.

.PARAMETER CsvPath
    Specifies the path to the CSV file. The CSV file should have the following columns: 'GroupName', 'Owner1', 'Owner2', 'Owner3', 'Owner4', 'Owner5'.

.EXAMPLE
    .    \AddOwnerstoGroups.ps1 -CsvPath .\ExampleGroupsOwners.csv

    This command reads the 'ExampleGroupsOwners.csv' file from the current directory and adds the owners to the groups as specified in the file.
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$CsvPath
)

# Connect to Azure AD
# Uncomment the line below and run it if you are not already connected
# Connect-AzureAD

# Import the CSV file
if (-not (Test-Path -Path $CsvPath)) {
    Write-Error "CSV file not found at path: $CsvPath"
    return
}

$csvData = Import-Csv -Path $CsvPath

foreach ($row in $csvData) {
    $groupName = $row.GroupName

    try {
        # Get the group object ID
        $groupObject = Get-AzureADGroup -Filter "DisplayName eq '$groupName'"
        if ($null -eq $groupObject) {
            Write-Warning "Group '$groupName' not found."
            continue
        }

        for ($i = 1; $i -le 5; $i++) {
            $ownerUipn = $row."Owner$i"

            if (-not ([string]::IsNullOrEmpty($ownerUipn))) {
                try {
                    # Get the owner object ID
                    $ownerObject = Get-AzureADUser -Filter "UserPrincipalName eq '$ownerUipn'"
                    if ($null -eq $ownerObject) {
                        Write-Warning "Owner '$ownerUipn' not found."
                        continue
                    }

                    # Add the owner to the group
                    Add-AzureADGroupOwner -ObjectId $groupObject.ObjectId -RefObjectId $ownerObject.ObjectId
                    Write-Host "Successfully added owner '$ownerUipn' to group '$groupName'."
                } catch {
                    Write-Error "An error occurred while adding owner '$ownerUipn' to group '$groupName'. Error: $_"
                }
            }
        }
    } catch {
        Write-Error "An error occurred while processing group '$groupName'. Error: $_"
    }
}