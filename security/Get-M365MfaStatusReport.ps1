param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\reports\mfa-status-report.csv"
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
        "UserAuthenticationMethod.Read.All",
        "AuditLog.Read.All",
        "Reports.Read.All"
    ) | Out-Null

    Write-Host "Connected successfully." -ForegroundColor Green
}
catch {
    Write-Error "Failed to connect to Microsoft Graph. $($_.Exception.Message)"
    exit 1
}

try {
    Write-Section "Retrieving user registration details"

    # Beta profile is required for authentication method registration details
    Select-MgProfile -Name "beta"

    $registrationDetails = Get-MgReportAuthenticationMethodUserRegistrationDetail -All

    if (-not $registrationDetails) {
        Write-Warning "No MFA registration data returned."
        Disconnect-MgGraph | Out-Null
        exit 0
    }

    $report = foreach ($user in $registrationDetails) {
        [PSCustomObject]@{
            DisplayName                  = $user.UserDisplayName
            UserPrincipalName            = $user.UserPrincipalName
            IsAdmin                      = $user.IsAdmin
            IsLicensed                   = $user.IsLicensed
            IsMfaCapable                 = $user.IsMfaCapable
            IsMfaRegistered              = $user.IsMfaRegistered
            IsPasswordlessCapable        = $user.IsPasswordlessCapable
            IsSsprCapable                = $user.IsSsprCapable
            IsSsprEnabled                = $user.IsSsprEnabled
            IsSsprRegistered             = $user.IsSsprRegistered
            MethodsRegistered            = ($user.MethodsRegistered -join "; ")
            DefaultMfaMethod             = $user.DefaultMfaMethod
            UserPreferredMethodForMfa    = $user.UserPreferredMethodForSecondaryAuthentication
            LastUpdatedDateTime          = $user.LastUpdatedDateTime
        }
    }

    Ensure-DirectoryExists -FilePath $OutputPath
    $report | Sort-Object UserPrincipalName | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

    Write-Section "Report Summary"

    $totalUsers         = $report.Count
    $mfaRegistered      = ($report | Where-Object { $_.IsMfaRegistered -eq $true }).Count
    $mfaNotRegistered   = ($report | Where-Object { $_.IsMfaRegistered -ne $true }).Count
    $admins             = ($report | Where-Object { $_.IsAdmin -eq $true }).Count
    $passwordlessUsers  = ($report | Where-Object { $_.IsPasswordlessCapable -eq $true }).Count

    Write-Host "Total users reviewed:       $totalUsers" -ForegroundColor Yellow
    Write-Host "MFA registered users:       $mfaRegistered" -ForegroundColor Green
    Write-Host "Users not MFA registered:   $mfaNotRegistered" -ForegroundColor Red
    Write-Host "Admin accounts:             $admins" -ForegroundColor Yellow
    Write-Host "Passwordless-capable users: $passwordlessUsers" -ForegroundColor Yellow

    Write-Host ""
    Write-Host "Report exported to: $OutputPath" -ForegroundColor Green
}
catch {
    Write-Error "Failed to generate MFA status report. $($_.Exception.Message)"
}
finally {
    Disconnect-MgGraph | Out-Null
    Write-Host "Disconnected from Microsoft Graph." -ForegroundColor Cyan
}
