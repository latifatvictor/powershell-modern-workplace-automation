param (
    [Parameter(Mandatory = $true)]
    [string]$CsvPath,

    [Parameter(Mandatory = $false)]
    [string]$LogPath = ".\logs\offboarding-log.csv"
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param (
        [string]$UserPrincipalName,
        [string]$Status,
        [string]$Message
    )

    $logEntry = [PSCustomObject]@{
        Timestamp         = (Get-Date).ToString("s")
        UserPrincipalName = $UserPrincipalName
        Status            = $Status
        Message           = $Message
    }

    $logDir = Split-Path -Path $LogPath -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    $logEntry | Export-Csv -Path $LogPath -Append -NoTypeInformation -Force
}

try {
    Connect-MgGraph -Scopes "User.ReadWrite.All", "Directory.ReadWrite.All"
    Write-Host "Connected to Microsoft Graph" -ForegroundColor Green
}
catch {
    Write-Error "Connection failed: $_"
    exit 1
}

$users = Import-Csv -Path $CsvPath

foreach ($user in $users) {
    try {
        Write-Host "Processing $($user.UserPrincipalName)..." -ForegroundColor Cyan

        $existingUser = Get-MgUser -Filter "userPrincipalName eq '$($user.UserPrincipalName)'" -ErrorAction SilentlyContinue

        if (-not $existingUser) {
            Write-Log $user.UserPrincipalName "Failed" "User not found"
            continue
        }

        # Disable account
        Update-MgUser -UserId $existingUser.Id -AccountEnabled:$false

        # Remove licenses
        $assignedLicenses = Get-MgUserLicenseDetail -UserId $existingUser.Id
        $licenseIds = $assignedLicenses | ForEach-Object { $_.SkuId }

        if ($licenseIds) {
            Set-MgUserLicense -UserId $existingUser.Id -RemoveLicenses $licenseIds -AddLicenses @{}
        }

        Write-Log $user.UserPrincipalName "Success" "User disabled and licenses removed"
        Write-Host "Offboarded $($user.UserPrincipalName)" -ForegroundColor Green
    }
    catch {
        Write-Log $user.UserPrincipalName "Failed" $_.Exception.Message
        Write-Warning "Error for $($user.UserPrincipalName)"
    }
}

Disconnect-MgGraph
Write-Host "Offboarding complete" -ForegroundColor Cyan
