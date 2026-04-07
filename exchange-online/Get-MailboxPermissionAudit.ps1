param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\reports\mailbox-permission-audit.csv",

    [Parameter(Mandatory = $false)]
    [switch]$IncludeSharedMailboxesOnly
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

function Add-Result {
    param (
        [System.Collections.Generic.List[object]]$Results,
        [string]$MailboxDisplayName,
        [string]$MailboxPrimarySmtpAddress,
        [string]$MailboxType,
        [string]$PermissionType,
        [string]$AssignedTo,
        [string]$AccessRights,
        [string]$Inherited,
        [string]$IsAutoMapping
    )

    $Results.Add([PSCustomObject]@{
        MailboxDisplayName        = $MailboxDisplayName
        MailboxPrimarySmtpAddress = $MailboxPrimarySmtpAddress
        MailboxType               = $MailboxType
        PermissionType            = $PermissionType
        AssignedTo                = $AssignedTo
        AccessRights              = $AccessRights
        Inherited                 = $Inherited
        AutoMapping               = $IsAutoMapping
    })
}

try {
    Write-Section "Connecting to Exchange Online"

    Connect-ExchangeOnline -ShowBanner:$false
    Write-Host "Connected successfully." -ForegroundColor Green
}
catch {
    Write-Error "Failed to connect to Exchange Online. $($_.Exception.Message)"
    exit 1
}

try {
    Write-Section "Retrieving mailboxes"

    if ($IncludeSharedMailboxesOnly) {
        $mailboxes = Get-ExoMailbox -RecipientTypeDetails SharedMailbox -ResultSize Unlimited -Properties DisplayName,PrimarySmtpAddress,RecipientTypeDetails
    }
    else {
        $mailboxes = Get-ExoMailbox -ResultSize Unlimited -Properties DisplayName,PrimarySmtpAddress,RecipientTypeDetails
    }

    if (-not $mailboxes) {
        Write-Warning "No mailboxes found."
        Disconnect-ExchangeOnline -Confirm:$false
        exit 0
    }

    $results = New-Object 'System.Collections.Generic.List[object]'

    foreach ($mailbox in $mailboxes) {
        Write-Host "Reviewing mailbox: $($mailbox.PrimarySmtpAddress)" -ForegroundColor Yellow

        # Full Access permissions
        $mailboxPermissions = Get-MailboxPermission -Identity $mailbox.PrimarySmtpAddress |
            Where-Object {
                $_.User -notlike "NT AUTHORITY\SELF" -and
                $_.User -notlike "S-1-5-*" -and
                $_.IsInherited -eq $false
            }

        foreach ($permission in $mailboxPermissions) {
            Add-Result -Results $results `
                -MailboxDisplayName $mailbox.DisplayName `
                -MailboxPrimarySmtpAddress $mailbox.PrimarySmtpAddress `
                -MailboxType $mailbox.RecipientTypeDetails `
                -PermissionType "FullAccess" `
                -AssignedTo ([string]$permission.User) `
                -AccessRights (($permission.AccessRights) -join "; ") `
                -Inherited ([string]$permission.IsInherited) `
                -IsAutoMapping ""
        }

        # Send As permissions
        $recipientPermissions = Get-RecipientPermission -Identity $mailbox.PrimarySmtpAddress |
            Where-Object {
                $_.Trustee -notlike "NT AUTHORITY\SELF" -and
                $_.Trustee -notlike "S-1-5-*"
            }

        foreach ($permission in $recipientPermissions) {
            Add-Result -Results $results `
                -MailboxDisplayName $mailbox.DisplayName `
                -MailboxPrimarySmtpAddress $mailbox.PrimarySmtpAddress `
                -MailboxType $mailbox.RecipientTypeDetails `
                -PermissionType "SendAs" `
                -AssignedTo ([string]$permission.Trustee) `
                -AccessRights (($permission.AccessRights) -join "; ") `
                -Inherited "" `
                -IsAutoMapping ""
        }

        # Send on Behalf permissions
        $sendOnBehalfUsers = $mailbox.GrantSendOnBehalfTo
        if ($sendOnBehalfUsers) {
            foreach ($delegate in $sendOnBehalfUsers) {
                Add-Result -Results $results `
                    -MailboxDisplayName $mailbox.DisplayName `
                    -MailboxPrimarySmtpAddress $mailbox.PrimarySmtpAddress `
                    -MailboxType $mailbox.RecipientTypeDetails `
                    -PermissionType "SendOnBehalf" `
                    -AssignedTo ([string]$delegate) `
                    -AccessRights "SendOnBehalf" `
                    -Inherited "" `
                    -IsAutoMapping ""
            }
        }
    }

    Ensure-DirectoryExists -FilePath $OutputPath
    $results | Sort-Object MailboxPrimarySmtpAddress, PermissionType, AssignedTo | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

    Write-Section "Report Summary"

    $totalMailboxes = $mailboxes.Count
    $totalEntries = $results.Count
    $fullAccessCount = ($results | Where-Object { $_.PermissionType -eq "FullAccess" }).Count
    $sendAsCount = ($results | Where-Object { $_.PermissionType -eq "SendAs" }).Count
    $sendOnBehalfCount = ($results | Where-Object { $_.PermissionType -eq "SendOnBehalf" }).Count

    Write-Host "Mailboxes reviewed:        $totalMailboxes" -ForegroundColor Yellow
    Write-Host "Permission entries found:  $totalEntries" -ForegroundColor Green
    Write-Host "Full Access entries:       $fullAccessCount" -ForegroundColor Yellow
    Write-Host "Send As entries:           $sendAsCount" -ForegroundColor Yellow
    Write-Host "Send on Behalf entries:    $sendOnBehalfCount" -ForegroundColor Yellow

    Write-Host ""
    Write-Host "Report exported to: $OutputPath" -ForegroundColor Green
}
catch {
    Write-Error "Failed to generate mailbox permission audit report. $($_.Exception.Message)"
}
finally {
    Disconnect-ExchangeOnline -Confirm:$false
    Write-Host "Disconnected from Exchange Online." -ForegroundColor Cyan
}
