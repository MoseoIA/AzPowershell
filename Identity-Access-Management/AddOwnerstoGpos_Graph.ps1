#Requires -Module Microsoft.Graph.Groups, Microsoft.Graph.Users

<#
.SYNOPSIS
    Adds owners to Azure AD security groups from a CSV file using the Microsoft.Graph module.

.DESCRIPTION
    This script reads a CSV file with a group name and up to 5 owners and adds the specified owners to the corresponding Azure AD security groups.
    It validates if a user is already an owner before attempting to add them.
    This script is compatible with PowerShell 7 and later.

.PARAMETER CsvPath
    Specifies the path to the CSV file. The CSV file should have the following columns: 'GroupName', 'Owner1', 'Owner2', 'Owner3', 'Owner4', 'Owner5'.

.EXAMPLE
    # First, ensure you are connected with the required permissions:
    # Connect-MgGraph -Scopes "Group.ReadWrite.All", "User.Read.All"

    .    \AddOwnerstoGpos_Graph.ps1 -CsvPath .\ExampleGroupsOwners.csv

    This command reads the 'ExampleGroupsOwners.csv' file from the current directory and adds the owners to the groups as specified in the file.
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$CsvPath
)

# Before running the script, ensure you have the necessary modules installed:
# Install-Module Microsoft.Graph.Groups, Microsoft.Graph.Users -Scope CurrentUser

# And connect to Microsoft Graph with the required permissions:
# Connect-MgGraph -Scopes "Group.ReadWrite.All", "User.Read.All"

# Import the CSV file
if (-not (Test-Path -Path $CsvPath)) {
    Write-Error "CSV file not found at path: $CsvPath"
    return
}

$csvData = Import-Csv -Path $CsvPath

foreach ($row in $csvData) {
    $groupName = $row.GroupName

    try {
        # Get the group object
        $groupObject = Get-MgGroup -Filter "DisplayName eq '$groupName'"
        if ($null -eq $groupObject) {
            Write-Warning "Group '$groupName' not found."
            continue
        }

        # Get current owners for validation
        $currentOwners = Get-MgGroupOwner -GroupId $groupObject.Id

        for ($i = 1; $i -le 5; $i++) {
            $ownerUipn = $row."Owner$i"

            if (-not ([string]::IsNullOrEmpty($ownerUipn))) {
                try {
                    # Get the owner object
                    $ownerObject = Get-MgUser -Filter "UserPrincipalName eq '$ownerUipn'"
                    if ($null -eq $ownerObject) {
                        Write-Warning "Owner '$ownerUipn' not found."
                        continue
                    }

                    # Validate if the user is already an owner
                    if ($ownerObject.Id -in $currentOwners.Id) {
                        Write-Host "User '$ownerUipn' is already an owner of group '$groupName'."
                    } else {
                        # Add the owner to the group by reference
                        $body = @{ "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($ownerObject.Id)" }
                        New-MgGroupOwnerByRef -GroupId $groupObject.Id -BodyParameter $body
                        Write-Host "Successfully added owner '$ownerUipn' to group '$groupName'."
                    }
                } catch {
                    Write-Error "An error occurred while adding owner '$ownerUipn' to group '$groupName'. Error: $($_.Exception.Message)"
                }
            }
        }
    } catch {
        Write-Error "An error occurred while processing group '$groupName'. Error: $($_.Exception.Message)"
    }
}