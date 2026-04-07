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


## Get-M365LicenseUsageReport.ps1

Generates a Microsoft 365 licence usage report showing enabled, consumed, and available licence capacity across subscribed SKUs.

### Key outputs
- SKU part number and ID
- enabled units
- consumed units
- available units
- utilisation percentage
- review flags for unused capacity

### Use case
Supports licence optimisation, cost awareness, and reporting by providing visibility into Microsoft 365 licence utilisation across the tenant.

