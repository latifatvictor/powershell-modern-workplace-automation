param (
    [Parameter(Mandatory = $false)]
    [int]$InactiveDays = 90,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\reports\inactive-users-report.csv"
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
        "User.Read.All",
        "Directory.Read.All",
        "AuditLog.Read.All"
    ) | Out-Null

    Write-Host "Connected successfully." -ForegroundColor Green
}
catch {
    Write-Error "Failed to connect to Microsoft Graph. $($_.Exception.Message)"
    exit 1
}

try {
    Write-Section "Retrieving users"

    $users = Get-MgUser -All -Property "id,displayName,userPrincipalName,accountEnabled,createdDateTime,signInActivity,department,jobTitle"

    if (-not $users) {
        Write-Warning "No users returned from Microsoft Graph."
        Disconnect-MgGraph | Out-Null
        exit 0
    }

    $cutoffDate = (Get-Date).AddDays(-$InactiveDays)

    Write-Section "Filtering inactive users"

    $inactiveUsers = foreach ($user in $users) {
        $lastSignIn = $null

        if ($user.SignInActivity -and $user.SignInActivity.LastSignInDateTime) {
            $lastSignIn = [datetime]$user.SignInActivity.LastSignInDateTime
        }

        $isInactive = $false

        if (-not $lastSignIn) {
            $isInactive = $true
        }
        elseif ($lastSignIn -lt $cutoffDate) {
            $isInactive = $true
        }

        if ($isInactive) {
            [PSCustomObject]@{
                DisplayName        = $user.DisplayName
                UserPrincipalName  = $user.UserPrincipalName
                AccountEnabled     = $user.AccountEnabled
                Department         = $user.Department
                JobTitle           = $user.JobTitle
                CreatedDateTime    = $user.CreatedDateTime
                LastSignInDateTime = $lastSignIn
                InactiveDays       = if ($lastSignIn) { ((Get-Date) - $lastSignIn).Days } else { "No sign-in recorded" }
                ReviewReason       = if (-not $lastSignIn) { "No sign-in activity found" } else { "Inactive for more than $InactiveDays days" }
            }
        }
    }

    Ensure-DirectoryExists -FilePath $OutputPath
    $inactiveUsers | Sort-Object UserPrincipalName | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

    Write-Section "Report Summary"

    $totalUsers = $users.Count
    $inactiveCount = $inactiveUsers.Count
    $enabledInactive = ($inactiveUsers | Where-Object { $_.AccountEnabled -eq $true }).Count
    $disabledInactive = ($inactiveUsers | Where-Object { $_.AccountEnabled -eq $false }).Count

    Write-Host "Total users reviewed:     $totalUsers" -ForegroundColor Yellow
    Write-Host "Inactive users found:     $inactiveCount" -ForegroundColor Red
    Write-Host "Enabled inactive users:   $enabledInactive" -ForegroundColor Yellow
    Write-Host "Disabled inactive users:  $disabledInactive" -ForegroundColor Green

    Write-Host ""
    Write-Host "Report exported to: $OutputPath" -ForegroundColor Green
}
catch {
    Write-Error "Failed to generate inactive users report. $($_.Exception.Message)"
}
finally {
    Disconnect-MgGraph | Out-Null
    Write-Host "Disconnected from Microsoft Graph." -ForegroundColor Cyan
}
