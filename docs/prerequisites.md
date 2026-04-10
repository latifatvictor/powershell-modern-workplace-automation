
---

# 🏆 2. `docs/prerequisites.md`

```markdown id="pre001"
# Prerequisites

## 📌 Overview

This document outlines the requirements needed to run the PowerShell scripts in this repository.

---

## 🛠️ Required Tools

### 1. PowerShell
- PowerShell 7.x (recommended)  
- Windows PowerShell 5.1 (supported but not preferred)

---

### 2. Microsoft Graph PowerShell SDK

Install using:

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser

---

3. Exchange Online Module (for mailbox scripts)
Install-Module ExchangeOnlineManagement -Scope CurrentUser

---

🔐 Required Permissions

Depending on the script, the following Microsoft Graph permissions may be required:

User.Read.All
User.ReadWrite.All
Directory.Read.All
Directory.ReadWrite.All
RoleManagement.Read.Directory
Policy.Read.All
DeviceManagementManagedDevices.ReadWrite.All
Reports.Read.All

⚠️ Always follow the principle of least privilege


---

🌐 Connectivity
Internet access to Microsoft 365 services
Access to Microsoft Graph API

---

📂 Input Files

Some scripts require CSV input files with structured fields such as:

UserPrincipalName
LicenseSkuPartNumber
Password
GroupIds

Ensure:

correct column names
valid formatting
no sensitive real data in public environments

---

🔒 Security Best Practices
Do not store credentials in scripts
Avoid using real user data in public repositories
Use secure password handling in production
Test scripts in non-production environments first

---

🧪 Testing Recommendation

Before running in production:

test scripts in a lab or sandbox tenant
validate outputs and logs
confirm permissions are correct

---

💭 Summary

Meeting these prerequisites ensures smooth execution, security, and reliability of all automation scripts in this repository.
