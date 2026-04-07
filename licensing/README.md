# Licensing Automation

Scripts for managing and optimising Microsoft 365 licences.

## 📌 Purpose
Automates licence assignment and provides visibility into licence usage.

## 📂 Scripts Included
- Set-M365LicenseAssignment.ps1  
- Get-M365LicenseUsageReport.ps1  

## ⚙️ Key Features
- Automated licence allocation  
- Licence usage reporting  
- Cost optimisation support  

## 🛠️ Requirements
- Microsoft Graph PowerShell SDK  

## 🚀 Use Cases
- Licence management  
- Cost optimisation  
- Reporting and analysis  


## Set-M365LicenseAssignment.ps1

Automates Microsoft 365 licence assignment for users from a CSV input file.

### Key outputs
- assigns licences based on SKU part number
- skips users who already have the licence
- logs successes, skips, and failures
- improves consistency in licence allocation

### Use case
Supports bulk licence assignment, onboarding workflows, and more efficient Microsoft 365 administration.
