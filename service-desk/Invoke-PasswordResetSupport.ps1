param (
    [Parameter(Mandatory = $true, ParameterSetName = "SingleUser")]
    [string]$UserPrincipalName,

    [Parameter(Mandatory = $true, ParameterSetName = "BulkUsers")]
    [string]$CsvPath,

    [Parameter(Mandatory = $false)]
    [string]$LogPath = ".\logs\password-reset-log.csv",

    [Parameter(Mandatory = $false)]
    [switch]$ForceChangeAtNextSignIn = $true,

    [Parameter(Mandatory = $false)]
    [switch]$GeneratePassword
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
        [string]$TemporaryPassword
    )

    $entry = [PSCustomObject]@{
        Timestamp         = (Get-Date).ToString("s")
        UserPrincipalName = $UserPrincipalName
        Status            = $Status
        Message           = $Message
        TemporaryPassword = $TemporaryPassword
    }

    Ensure-DirectoryExists -FilePath $LogPath
    $entry | Export-Csv -Path $LogPath -Append -NoTypeInformation -Encoding UTF8
}

function New-TemporaryPassword {
    param (
        [int]$Length = 14
    )

    $upper = "ABCDEFGHJKLMNPQRSTUVWXYZ"
    $lower = "abcdefghijkmnopqrstuvwxyz"
    $numbers = "23456789"
    $special = "!@#$%&*?"

    $allChars = ($upper + $lower + $numbers + $special).ToCharArray()

    $passwordChars = @()
    $passwordChars += $upper[(Get-Random -Minimum 0 -Maximum $upper.Length)]
    $passwordChars += $lower[(Get-Random -Minimum 0 -Maximum $lower.Length)]
    $passwordChars += $numbers[(Get-Random -Minimum 0 -Maximum $numbers.Length)]
    $passwordChars += $special[(Get-Random -Minimum 0 -Maximum $special.Length)]

    for ($i = $passwordChars.Count; $i -lt $Length; $i++) {
        $passwordChars += $allChars[(Get-Random -Minimum 0 -Maximum $allChars.Length)]
    }

    -join ($passwordChars | Sort-Object { Get-Random })
}

function Get-ResetTargets {
    if ($PSCmdlet.ParameterSetName -eq "SingleUser") {
        return @([PSCustomObject]@{
            UserPrincipalName = $UserPrincipalName
        })
    }

    $records = Import-Csv -Path $CsvPath

    if (-not $records) {
        throw "No records found in CSV."
    }

    foreach ($record in $records) {
        if (-not $record.UserPrincipalName) {
            throw "CSV must contain a 'UserPrincipalName' column."
        }
    }

    return $records
}

try {
    Write-Host "=== Connecting to Microsoft Graph ===" -ForegroundColor Cyan

    Connect-MgGraph -Scopes @(
        "User.ReadWrite.All",
        "Directory.AccessAsUser.All"
    ) | Out-Null

    Write-Host "Connected successfully." -ForegroundColor Green
}
catch {
    Write-Error "Failed to connect to Microsoft Graph. $($_.Exception.Message)"
    exit 1
}

try {
    $targets = Get-ResetTargets

    foreach ($target in $targets) {
        $upn = $target.UserPrincipalName

        try {
            Write-Host "Processing password reset for $upn..." -ForegroundColor Yellow

            $user = Get-MgUser -Filter "userPrincipalName eq '$upn'" -ErrorAction SilentlyContinue

            if (-not $user) {
                Write-Log -UserPrincipalName $upn -Status "Failed" -Message "User not found." -TemporaryPassword ""
                Write-Warning "User not found: $upn"
                continue
            }

            $temporaryPassword = if ($GeneratePassword) {
                New-TemporaryPassword
            }
            elseif ($target.TemporaryPassword) {
                $target.TemporaryPassword
            }
            else {
                throw "No password source provided. Use -GeneratePassword or provide TemporaryPassword in CSV."
            }

            $passwordProfile = @{
                ForceChangePasswordNextSignIn = [bool]$ForceChangeAtNextSignIn
                Password                      = $temporaryPassword
            }

            Update-MgUser -UserId $user.Id -PasswordProfile $passwordProfile

            Write-Log -UserPrincipalName $upn -Status "Success" -Message "Password reset completed successfully." -TemporaryPassword $temporaryPassword
            Write-Host "Password reset completed for $upn" -ForegroundColor Green
        }
        catch {
            Write-Log -UserPrincipalName $upn -Status "Failed" -Message $_.Exception.Message -TemporaryPassword ""
            Write-Warning "Failed for $upn: $($_.Exception.Message)"
        }
    }

    Write-Host ""
    Write-Host "Password reset process complete." -ForegroundColor Cyan
    Write-Host "Log exported to: $LogPath" -ForegroundColor Green
}
catch {
    Write-Error "Script failed. $($_.Exception.Message)"
}
finally {
    Disconnect-MgGraph | Out-Null
    Write-Host "Disconnected from Microsoft Graph." -ForegroundColor Cyan
}
