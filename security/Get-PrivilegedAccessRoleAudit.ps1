param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\reports\privileged-access-role-audit.csv"
)

$ErrorActionPreference = "Stop"

function Ensure-DirectoryExists {
    param (
        [string]$FilePath
    )

    $directory = Split-Path -Path $FilePath -Parent
    if (-not (Test-Path $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
}

function Write-Section {
    param (
        [string]$Message
    )

    Write-Host ""
    Write-Host "=== $Message ===" -ForegroundColor Cyan
}

try {
    Write-Section "Connecting to Microsoft Graph"

    Connect-MgGraph -Scopes @(
        "RoleManagement.Read.Directory",
        "Directory.Read.All",
        "User.Read.All"
    ) | Out-Null

    Write-Host "Connected successfully." -ForegroundColor Green
}
catch {
    Write-Error "Failed to connect to Microsoft Graph. $($_.Exception.Message)"
    exit 1
}

try {
    Write-Section "Retrieving directory roles"

    $roles = Get-MgDirectoryRole

    if (-not $roles) {
        Write-Warning "No active directory roles found."
        Disconnect-MgGraph | Out-Null
        exit 0
    }

    $report = foreach ($role in $roles) {
        $members = Get-MgDirectoryRoleMember -DirectoryRoleId $role.Id -All

        if (-not $members) {
            [PSCustomObject]@{
                RoleName           = $role.DisplayName
                MemberDisplayName  = "No members assigned"
                UserPrincipalName  = ""
                ObjectType         = ""
                AssignmentStatus   = "Empty role"
            }
            continue
        }

        foreach ($member in $members) {
            $memberType = $member.AdditionalProperties.'@odata.type'
            $displayName = $member.AdditionalProperties.displayName
            $userPrincipalName = $member.AdditionalProperties.userPrincipalName

            [PSCustomObject]@{
                RoleName           = $role.DisplayName
                MemberDisplayName  = $displayName
                UserPrincipalName  = $userPrincipalName
                ObjectType         = $memberType
                AssignmentStatus   = "Assigned"
            }
        }
    }

    Ensure-DirectoryExists -FilePath $OutputPath
    $report | Sort-Object RoleName, MemberDisplayName | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

    Write-Section "Report Summary"

    $totalRoles = ($report | Select-Object -ExpandProperty RoleName -Unique).Count
    $assignedEntries = ($report | Where-Object { $_.AssignmentStatus -eq "Assigned" }).Count
    $emptyRoles = ($report | Where-Object { $_.AssignmentStatus -eq "Empty role" }).Count

    Write-Host "Roles reviewed:          $totalRoles" -ForegroundColor Yellow
    Write-Host "Assigned role entries:   $assignedEntries" -ForegroundColor Green
    Write-Host "Empty roles:             $emptyRoles" -ForegroundColor Yellow

    Write-Host ""
    Write-Host "Report exported to: $OutputPath" -ForegroundColor Green
}
catch {
    Write-Error "Failed to generate privileged access audit report. $($_.Exception.Message)"
}
finally {
    Disconnect-MgGraph | Out-Null
    Write-Host "Disconnected from Microsoft Graph." -ForegroundColor Cyan
}
