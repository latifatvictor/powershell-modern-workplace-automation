param (
    [Parameter(Mandatory = $false)]
    [string]$ReviewType = "UsersAndRoles",

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\reports\access-review-report.csv"
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

function Add-ReviewEntry {
    param (
        [System.Collections.Generic.List[object]]$Results,
        [string]$ReviewCategory,
        [string]$DisplayName,
        [string]$UserPrincipalName,
        [string]$ObjectType,
        [string]$ReviewReason,
        [string]$RecommendedAction
    )

    $Results.Add([PSCustomObject]@{
        ReviewCategory     = $ReviewCategory
        DisplayName        = $DisplayName
        UserPrincipalName  = $UserPrincipalName
        ObjectType         = $ObjectType
        ReviewReason       = $ReviewReason
        RecommendedAction  = $RecommendedAction
    })
}

try {
    Write-Section "Connecting to Microsoft Graph"

    Connect-MgGraph -Scopes @(
        "User.Read.All",
        "Directory.Read.All",
        "RoleManagement.Read.Directory",
        "Group.Read.All"
    ) | Out-Null

    Write-Host "Connected successfully." -ForegroundColor Green
}
catch {
    Write-Error "Failed to connect to Microsoft Graph. $($_.Exception.Message)"
    exit 1
}

try {
    $results = New-Object 'System.Collections.Generic.List[object]'

    if ($ReviewType -eq "UsersAndRoles" -or $ReviewType -eq "UsersOnly") {
        Write-Section "Reviewing users"

        $users = Get-MgUser -All -Property "displayName,userPrincipalName,accountEnabled,createdDateTime,signInActivity"

        foreach ($user in $users) {
            $lastSignIn = $null

            if ($user.SignInActivity -and $user.SignInActivity.LastSignInDateTime) {
                $lastSignIn = [datetime]$user.SignInActivity.LastSignInDateTime
            }

            if (-not $user.AccountEnabled) {
                Add-ReviewEntry -Results $results `
                    -ReviewCategory "UserAccount" `
                    -DisplayName $user.DisplayName `
                    -UserPrincipalName $user.UserPrincipalName `
                    -ObjectType "User" `
                    -ReviewReason "Account is disabled" `
                    -RecommendedAction "Confirm whether account should remain disabled or be removed"
            }
            elseif (-not $lastSignIn) {
                Add-ReviewEntry -Results $results `
                    -ReviewCategory "UserAccount" `
                    -DisplayName $user.DisplayName `
                    -UserPrincipalName $user.UserPrincipalName `
                    -ObjectType "User" `
                    -ReviewReason "No recorded sign-in activity found" `
                    -RecommendedAction "Review access necessity and consider deprovisioning if inactive"
            }
        }
    }

    if ($ReviewType -eq "UsersAndRoles" -or $ReviewType -eq "RolesOnly") {
        Write-Section "Reviewing privileged roles"

        $roles = Get-MgDirectoryRole

        foreach ($role in $roles) {
            $members = Get-MgDirectoryRoleMember -DirectoryRoleId $role.Id -All

            if (-not $members) {
                Add-ReviewEntry -Results $results `
                    -ReviewCategory "PrivilegedRole" `
                    -DisplayName $role.DisplayName `
                    -UserPrincipalName "" `
                    -ObjectType "DirectoryRole" `
                    -ReviewReason "Privileged role exists with no assigned members" `
                    -RecommendedAction "Review role necessity and governance relevance"
            }
            else {
                foreach ($member in $members) {
                    $displayName = $member.AdditionalProperties.displayName
                    $upn = $member.AdditionalProperties.userPrincipalName
                    $odataType = $member.AdditionalProperties.'@odata.type'

                    Add-ReviewEntry -Results $results `
                        -ReviewCategory "PrivilegedRole" `
                        -DisplayName "$displayName ($($role.DisplayName))" `
                        -UserPrincipalName $upn `
                        -ObjectType $odataType `
                        -ReviewReason "Member assigned to privileged role" `
                        -RecommendedAction "Validate role assignment against least-privilege requirements"
                }
            }
        }
    }

    Ensure-DirectoryExists -FilePath $OutputPath
    $results | Sort-Object ReviewCategory, DisplayName | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

    Write-Section "Report Summary"

    $totalEntries = $results.Count
    $userEntries = ($results | Where-Object { $_.ReviewCategory -eq "UserAccount" }).Count
    $roleEntries = ($results | Where-Object { $_.ReviewCategory -eq "PrivilegedRole" }).Count

    Write-Host "Total review entries:      $totalEntries" -ForegroundColor Yellow
    Write-Host "User account reviews:      $userEntries" -ForegroundColor Green
    Write-Host "Privileged role reviews:   $roleEntries" -ForegroundColor Green

    Write-Host ""
    Write-Host "Report exported to: $OutputPath" -ForegroundColor Green
}
catch {
    Write-Error "Failed to generate access review report. $($_.Exception.Message)"
}
finally {
    Disconnect-MgGraph | Out-Null
    Write-Host "Disconnected from Microsoft Graph." -ForegroundColor Cyan
}
