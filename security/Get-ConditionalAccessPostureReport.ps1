param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\reports\conditional-access-posture-report.csv"
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

function Convert-ToFriendlyText {
    param (
        [object]$Value
    )

    if ($null -eq $Value) {
        return ""
    }

    if ($Value -is [System.Array]) {
        return ($Value -join "; ")
    }

    return [string]$Value
}

try {
    Write-Section "Connecting to Microsoft Graph"

    Connect-MgGraph -Scopes @(
        "Policy.Read.All",
        "Directory.Read.All",
        "Application.Read.All"
    ) | Out-Null

    Write-Host "Connected successfully." -ForegroundColor Green
}
catch {
    Write-Error "Failed to connect to Microsoft Graph. $($_.Exception.Message)"
    exit 1
}

try {
    Write-Section "Retrieving Conditional Access policies"

    Select-MgProfile -Name "beta"

    $policies = Get-MgIdentityConditionalAccessPolicy -All

    if (-not $policies) {
        Write-Warning "No Conditional Access policies found."
        Disconnect-MgGraph | Out-Null
        exit 0
    }

    $report = foreach ($policy in $policies) {
        $conditions = $policy.Conditions
        $grantControls = $policy.GrantControls
        $sessionControls = $policy.SessionControls

        [PSCustomObject]@{
            PolicyName                    = $policy.DisplayName
            State                         = $policy.State
            CreatedDateTime               = $policy.CreatedDateTime
            ModifiedDateTime              = $policy.ModifiedDateTime
            IncludedUsers                 = Convert-ToFriendlyText $conditions.Users.IncludeUsers
            ExcludedUsers                 = Convert-ToFriendlyText $conditions.Users.ExcludeUsers
            IncludedGroups                = Convert-ToFriendlyText $conditions.Users.IncludeGroups
            ExcludedGroups                = Convert-ToFriendlyText $conditions.Users.ExcludeGroups
            IncludedRoles                 = Convert-ToFriendlyText $conditions.Users.IncludeRoles
            ExcludedRoles                 = Convert-ToFriendlyText $conditions.Users.ExcludeRoles
            IncludedApplications          = Convert-ToFriendlyText $conditions.Applications.IncludeApplications
            ExcludedApplications          = Convert-ToFriendlyText $conditions.Applications.ExcludeApplications
            IncludedUserActions           = Convert-ToFriendlyText $conditions.Applications.IncludeUserActions
            IncludedPlatforms             = Convert-ToFriendlyText $conditions.Platforms.IncludePlatforms
            ExcludedPlatforms             = Convert-ToFriendlyText $conditions.Platforms.ExcludePlatforms
            IncludedLocations             = Convert-ToFriendlyText $conditions.Locations.IncludeLocations
            ExcludedLocations             = Convert-ToFriendlyText $conditions.Locations.ExcludeLocations
            ClientAppTypes                = Convert-ToFriendlyText $conditions.ClientAppTypes
            SignInRiskLevels              = Convert-ToFriendlyText $conditions.SignInRiskLevels
            UserRiskLevels                = Convert-ToFriendlyText $conditions.UserRiskLevels
            GrantOperator                 = $grantControls.Operator
            BuiltInGrantControls          = Convert-ToFriendlyText $grantControls.BuiltInControls
            CustomAuthenticationFactors   = Convert-ToFriendlyText $grantControls.CustomAuthenticationFactors
            TermsOfUse                    = Convert-ToFriendlyText $grantControls.TermsOfUse
            HasApplicationEnforcedControl = if ($sessionControls.ApplicationEnforcedRestrictions.IsEnabled) { "Yes" } else { "No" }
            HasSignInFrequency            = if ($sessionControls.SignInFrequency.IsEnabled) { "Yes" } else { "No" }
            SignInFrequencyType           = $sessionControls.SignInFrequency.Type
            SignInFrequencyValue          = $sessionControls.SignInFrequency.Value
            HasPersistentBrowserControl   = if ($sessionControls.PersistentBrowser.IsEnabled) { "Yes" } else { "No" }
            PersistentBrowserMode         = $sessionControls.PersistentBrowser.Mode
        }
    }

    Ensure-DirectoryExists -FilePath $OutputPath
    $report | Sort-Object PolicyName | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

    Write-Section "Report Summary"

    $totalPolicies   = $report.Count
    $enabledPolicies = ($report | Where-Object { $_.State -eq "enabled" }).Count
    $disabledPolicies = ($report | Where-Object { $_.State -eq "disabled" }).Count
    $reportOnlyPolicies = ($report | Where-Object { $_.State -eq "enabledForReportingButNotEnforced" }).Count

    Write-Host "Total policies reviewed:   $totalPolicies" -ForegroundColor Yellow
    Write-Host "Enabled policies:          $enabledPolicies" -ForegroundColor Green
    Write-Host "Disabled policies:         $disabledPolicies" -ForegroundColor Red
    Write-Host "Report-only policies:      $reportOnlyPolicies" -ForegroundColor Yellow

    Write-Host ""
    Write-Host "Report exported to: $OutputPath" -ForegroundColor Green
}
catch {
    Write-Error "Failed to generate Conditional Access posture report. $($_.Exception.Message)"
}
finally {
    Disconnect-MgGraph | Out-Null
    Write-Host "Disconnected from Microsoft Graph." -ForegroundColor Cyan
}
