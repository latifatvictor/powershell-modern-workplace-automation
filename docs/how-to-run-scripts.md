# How to run scripts in this repository

## Requirements
- PowerShell 7 recommended
- Microsoft Graph PowerShell modules (scripts install/import required modules)

## General guidance
- Read the script header for required permissions
- Test in a non-production environment first
- Keep exports private (do not commit CSV/JSON outputs)

## Example
Run the Intune compliance report:

```powershell
.\scripts\intune-device-compliance-report.ps1
