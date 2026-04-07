param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\reports\m365-license-usage-report.csv"
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
        "Organization.Read.All",
        "Directory.Read.All"
    ) | Out-Null

    Write-Host "Connected successfully." -ForegroundColor Green
}
catch {
    Write-Error "Failed to connect to Microsoft Graph. $($_.Exception.Message)"
    exit 1
}

try {
    Write-Section "Retrieving subscribed SKUs"

    $subscribedSkus = Get-MgSubscribedSku

    if (-not $subscribedSkus) {
        Write-Warning "No subscribed SKUs found."
        Disconnect-MgGraph | Out-Null
        exit 0
    }

    $report = foreach ($sku in $subscribedSkus) {
        $enabledUnits = [int]$sku.PrepaidUnits.Enabled
        $suspendedUnits = [int]$sku.PrepaidUnits.Suspended
        $warningUnits = [int]$sku.PrepaidUnits.Warning
        $consumedUnits = [int]$sku.ConsumedUnits
        $availableUnits = $enabledUnits - $consumedUnits

        [PSCustomObject]@{
            SkuPartNumber       = $sku.SkuPartNumber
            SkuId               = $sku.SkuId
            EnabledUnits        = $enabledUnits
            ConsumedUnits       = $consumedUnits
            AvailableUnits      = $availableUnits
            SuspendedUnits      = $suspendedUnits
            WarningUnits        = $warningUnits
            UtilisationPercent  = if ($enabledUnits -gt 0) { [math]::Round(($consumedUnits / $enabledUnits) * 100, 2) } else { 0 }
            ReviewFlag          = if ($availableUnits -gt 0) { "Review unused capacity" } elseif ($availableUnits -eq 0) { "Fully allocated" } else { "Check allocation" }
        }
    }

    Ensure-DirectoryExists -FilePath $OutputPath
    $report | Sort-Object SkuPartNumber | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

    Write-Section "Report Summary"

    $totalSkus = $report.Count
    $totalEnabled = ($report | Measure-Object -Property EnabledUnits -Sum).Sum
    $totalConsumed = ($report | Measure-Object -Property ConsumedUnits -Sum).Sum
    $totalAvailable = ($report | Measure-Object -Property AvailableUnits -Sum).Sum
    $fullyAllocated = ($report | Where-Object { $_.AvailableUnits -eq 0 }).Count
    $withUnusedCapacity = ($report | Where-Object { $_.AvailableUnits -gt 0 }).Count

    Write-Host "Total licence SKUs reviewed:   $totalSkus" -ForegroundColor Yellow
    Write-Host "Total enabled units:           $totalEnabled" -ForegroundColor Green
    Write-Host "Total consumed units:          $totalConsumed" -ForegroundColor Green
    Write-Host "Total available units:         $totalAvailable" -ForegroundColor Yellow
    Write-Host "Fully allocated SKUs:          $fullyAllocated" -ForegroundColor Yellow
    Write-Host "SKUs with unused capacity:     $withUnusedCapacity" -ForegroundColor Yellow

    Write-Host ""
    Write-Host "Report exported to: $OutputPath" -ForegroundColor Green
}
catch {
    Write-Error "Failed to generate Microsoft 365 licence usage report. $($_.Exception.Message)"
}
finally {
    Disconnect-MgGraph | Out-Null
    Write-Host "Disconnected from Microsoft Graph." -ForegroundColor Cyan
}
