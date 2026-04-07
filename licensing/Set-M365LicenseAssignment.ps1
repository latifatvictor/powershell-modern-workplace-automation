param (
    [Parameter(Mandatory = $true)]
    [string]$CsvPath,

    [Parameter(Mandatory = $false)]
    [string]$LogPath = ".\reports\license-assignment-log.csv"
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

function Write-Log {
    param (
        [string]$UserPrincipalName,
        [string]$Status,
        [string]$Message,
        [string]$LicenseSkuPartNumber
    )

    $entry = [PSCustomObject]@{
        Timestamp            = (Get-Date).ToString("s")
        UserPrincipalName    = $UserPrincipalName
        LicenseSkuPartNumber = $LicenseSkuPartNumber
        Status               = $Status
        Message              = $Message
    }

    Ensure-DirectoryExists -FilePath $LogPath
    $entry | Export-Csv -Path $LogPath -Append -NoTypeInformation -Encoding UTF8
}

function Get-LicenseSkuMap {
    $skuMap = @{}
    $subscribedSkus = Get-MgSubscribedSku

    foreach ($sku in $subscribedSkus) {
        $skuMap[$sku.SkuPartNumber] = $sku.SkuId
    }

    return $skuMap
}

try {
    Write-Host "=== Connecting to Microsoft Graph ===" -ForegroundColor Cyan

    Connect-MgGraph -Scopes @(
        "User.ReadWrite.All",
        "Directory.ReadWrite.All",
        "Organization.Read.All"
    ) | Out-Null

    Write-Host "Connected successfully." -ForegroundColor Green
}
catch {
    Write-Error "Failed to connect to Microsoft Graph. $($_.Exception.Message)"
    exit 1
}

try {
    Write-Host "=== Importing CSV ===" -ForegroundColor Cyan
    $records = Import-Csv -Path $CsvPath

    if (-not $records) {
        throw "No records found in CSV."
    }

    Write-Host "=== Retrieving subscribed SKUs ===" -ForegroundColor Cyan
    $skuMap = Get-LicenseSkuMap

    foreach ($record in $records) {
        try {
            $upn = $record.UserPrincipalName
            $licenseSku = $record.LicenseSkuPartNumber

            if ([string]::IsNullOrWhiteSpace($upn) -or [string]::IsNullOrWhiteSpace($licenseSku)) {
                Write-Log -UserPrincipalName $upn -Status "Failed" -Message "Missing UserPrincipalName or LicenseSkuPartNumber." -LicenseSkuPartNumber $licenseSku
                Write-Warning "Skipping record with missing values."
                continue
            }

            Write-Host "Processing $upn..." -ForegroundColor Yellow

            $user = Get-MgUser -Filter "userPrincipalName eq '$upn'" -ErrorAction SilentlyContinue

            if (-not $user) {
                Write-Log -UserPrincipalName $upn -Status "Failed" -Message "User not found." -LicenseSkuPartNumber $licenseSku
                Write-Warning "User not found: $upn"
                continue
            }

            if (-not $skuMap.ContainsKey($licenseSku)) {
                Write-Log -UserPrincipalName $upn -Status "Failed" -Message "Licence SKU not found in tenant." -LicenseSkuPartNumber $licenseSku
                Write-Warning "Licence SKU not found: $licenseSku"
                continue
            }

            $licenseSkuId = $skuMap[$licenseSku]

            $existingLicenses = Get-MgUserLicenseDetail -UserId $user.Id
            $alreadyAssigned = $existingLicenses | Where-Object { $_.SkuPartNumber -eq $licenseSku }

            if ($alreadyAssigned) {
                Write-Log -UserPrincipalName $upn -Status "Skipped" -Message "Licence already assigned." -LicenseSkuPartNumber $licenseSku
                Write-Host "Licence already assigned to $upn" -ForegroundColor DarkYellow
                continue
            }

            Set-MgUserLicense `
                -UserId $user.Id `
                -AddLicenses @(@{ SkuId = $licenseSkuId }) `
                -RemoveLicenses @()

            Write-Log -UserPrincipalName $upn -Status "Success" -Message "Licence assigned successfully." -LicenseSkuPartNumber $licenseSku
            Write-Host "Assigned $licenseSku to $upn" -ForegroundColor Green
        }
        catch {
            Write-Log -UserPrincipalName $record.UserPrincipalName -Status "Failed" -Message $_.Exception.Message -LicenseSkuPartNumber $record.LicenseSkuPartNumber
            Write-Warning "Failed for $($record.UserPrincipalName): $($_.Exception.Message)"
        }
    }

    Write-Host "=== Processing complete ===" -ForegroundColor Cyan
    Write-Host "Log exported to: $LogPath" -ForegroundColor Green
}
catch {
    Write-Error "Script failed. $($_.Exception.Message)"
}
finally {
    Disconnect-MgGraph | Out-Null
    Write-Host "Disconnected from Microsoft Graph." -ForegroundColor Cyan
}
