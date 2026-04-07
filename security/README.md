# Security & Identity Reporting

Scripts focused on improving visibility into identity and security posture.

## 📌 Purpose
Supports monitoring and governance of identity, access, and security configurations.

## 📂 Scripts Included
- Get-M365MfaStatusReport.ps1  
- Get-PrivilegedAccessRoleAudit.ps1  
- Get-ConditionalAccessPostureReport.ps1  

## ⚙️ Key Features
- MFA coverage reporting  
- Privileged access visibility  
- Conditional Access analysis  

## 🛠️ Requirements
- Microsoft Graph PowerShell SDK  

## 🚀 Use Cases
- Security audits  
- Compliance checks  
- Risk identification

## Get-M365MfaStatusReport.ps1

Generates a report showing MFA registration and authentication method status for Microsoft 365 users.

### Key outputs
- MFA registration status
- registered authentication methods
- default MFA method
- admin account visibility
- passwordless and SSPR capability

### Use case
Supports security reviews, governance checks, and MFA posture reporting across the tenant.

## Get-PrivilegedAccessRoleAudit.ps1

Generates a report of Microsoft Entra directory roles and their assigned members.

### Key outputs
- active directory roles
- assigned members per role
- user principal names
- object types
- empty privileged roles

### Use case
Supports privileged access reviews, governance checks, and audit readiness by improving visibility of elevated role assignments.

## Get-ConditionalAccessPostureReport.ps1

Generates a report of Conditional Access policies in Microsoft Entra ID.

### Key outputs
- policy names and states
- included and excluded users, groups, and roles
- targeted applications and locations
- grant controls such as MFA
- session controls such as sign-in frequency

### Use case
Supports security posture reviews, Conditional Access governance, and policy visibility across the tenant.
