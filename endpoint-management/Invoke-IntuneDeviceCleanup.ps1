param (
    [Parameter(Mandatory = $false)]
    [int]$InactiveDays = 90,

    [Parameter(Mandatory = $false)]
    [switch]$Cleanup,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\reports\intune-device-cleanup-report.csv"
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

function Get-InactiveReason {
    param (
        [Nullable[datetime]]$LastSyncDateTime,
        [int]$ThresholdDays
    )

    if (-not $LastSyncDateTime) {
        return "No last sync recorded"
    }

    $daysSinceSync = ((Get-Date) - $LastSyncDateTime).Days

    if ($daysSinceSync -gt $ThresholdDays) {
        return "Inactive for more than $ThresholdDays days"
    }

    return $null
}

try {
    Write-Section "Connecting to Microsoft Graph"

    Connect-MgGraph -Scopes @(
        "DeviceManagementManagedDevices.ReadWrite.All",
        "Directory.Read.All"
    ) | Out-Null

    Select-MgProfile -Name "beta"

    Write-Host "Connected successfully." -ForegroundColor Green
}
catch {
    Write-Error "Failed to connect to Microsoft Graph. $($_.Exception.Message)"
    exit 1
}

try {
    Write-Section "Retrieving managed devices from Intune"

    $devices = Get-MgDeviceManagementManagedDevice -All

    if (-not $devices) {
        Write-Warning "No managed devices returned."
        Disconnect-MgGraph | Out-Null
        exit 0
    }

    $staleDevices = foreach ($device in $devices) {
        $lastSync = $null

        if ($device.LastSyncDateTime) {
            $lastSync = [datetime]$device.LastSyncDateTime
        }

        $inactiveReason = Get-InactiveReason -LastSyncDateTime $lastSync -ThresholdDays $InactiveDays

        if ($inactiveReason) {
            [PSCustomObject]@{
                DeviceName         = $device.DeviceName
                UserPrincipalName  = $device.UserPrincipalName
                OperatingSystem    = $device.OperatingSystem
                OSVersion          = $device.OsVersion
                ComplianceState    = $device.ComplianceState
                ManagementState    = $device.ManagementState
                LastSyncDateTime   = $lastSync
                InactiveDays       = if ($lastSync) { ((Get-Date) - $lastSync).Days } else { "No sync recorded" }
                AzureAdDeviceId    = $device.AzureAdDeviceId
                ManagedDeviceId    = $device.Id
                ReviewReason       = $inactiveReason
                CleanupActionTaken = "No"
            }
        }
    }

    if ($Cleanup -and $staleDevices) {
        Write-Section "Cleanup mode enabled - retiring stale devices"

        foreach ($staleDevice in $staleDevices) {
            try {
                Invoke-MgRetireDeviceManagementManagedDevice -ManagedDeviceId $staleDevice.ManagedDeviceId
                $staleDevice.CleanupActionTaken = "Yes"
                Write-Host "Retired device: $($staleDevice.DeviceName)" -ForegroundColor Yellow
            }
            catch {
                Write-Warning "Failed to retire device $($staleDevice.DeviceName): $($_.Exception.Message)"
            }
        }
    }

    Ensure-DirectoryExists -FilePath $OutputPath
    $staleDevices | Sort-Object DeviceName | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

    Write-Section "Report Summary"

    $totalDevices = $devices.Count
    $staleCount = $staleDevices.Count
    $compliantStale = ($staleDevices | Where-Object { $_.ComplianceState -eq "compliant" }).Count
    $nonCompliantStale = ($staleDevices | Where-Object { $_.ComplianceState -ne "compliant" }).Count
    $cleanupCount = ($staleDevices | Where-Object { $_.CleanupActionTaken -eq "Yes" }).Count

    Write-Host "Total managed devices reviewed:   $totalDevices" -ForegroundColor Yellow
    Write-Host "Stale devices identified:         $staleCount" -ForegroundColor Red
    Write-Host "Compliant stale devices:          $compliantStale" -ForegroundColor Yellow
    Write-Host "Non-compliant stale devices:      $nonCompliantStale" -ForegroundColor Yellow
    Write-Host "Devices retired in this run:      $cleanupCount" -ForegroundColor Green

    Write-Host ""
    Write-Host "Report exported to: $OutputPath" -ForegroundColor Green
}
catch {
    Write-Error "Failed to process Intune device cleanup. $($_.Exception.Message)"
}
finally {
    Disconnect-MgGraph | Out-Null
    Write-Host "Disconnected from Microsoft Graph." -ForegroundColor Cyan
}
