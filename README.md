# Microsoft 365 PowerShell Automation Scripts

A collection of PowerShell scripts designed to automate **user lifecycle management, security reporting, and administrative tasks** across Microsoft 365 and Microsoft Entra ID.

---

## 🚀 Overview

This repository contains practical automation scripts that improve efficiency, strengthen governance, and reduce manual effort in Microsoft 365 environments.

The scripts focus on:

- user onboarding and offboarding  
- licence management  
- identity and access governance  
- security reporting and visibility  
- environment clean-up and optimisation  

---

## 🧠 Why This Repository Exists

Modern IT environments require automation to remain efficient, secure, and scalable.

This repository demonstrates how PowerShell can be used to:

- standardise administrative processes  
- reduce human error  
- improve visibility into security and access  
- support governance and compliance initiatives  

---

## 🛠️ Technologies Used

- PowerShell  
- Microsoft Graph PowerShell SDK  
- Microsoft Entra ID  
- Microsoft 365 (Exchange, Teams, SharePoint, Intune)  

---

## ⚙️ Script Categories

---

### 👤 User Lifecycle Management

#### User Onboarding Automation
Automates user creation, licence assignment, and group membership  
Improves onboarding consistency and reduces provisioning delays  

#### User Offboarding Automation
Automates account deactivation and access removal  
Reduces security risk and ensures proper leaver processes  

---

### 🪪 Licence Management

#### Licence Assignment Automation
Automates licence allocation based on user requirements  
Improves efficiency and reduces manual administration  

---

### 🔐 Security & Identity Reporting

#### MFA Status Reporting
Provides visibility into Multi-Factor Authentication coverage  
Supports security posture monitoring  

#### Privileged Access / Role Audit
Reports on admin roles and elevated access  
Supports least-privilege and governance initiatives  

#### Conditional Access Posture Report
Evaluates policy coverage and identifies potential gaps  
Supports security review and improvement  

---

### 📊 Governance & Compliance

#### Access Review Automation
Supports periodic review of user access  
Helps reduce inappropriate or outdated permissions  

#### Mailbox Permission Audit
Reviews delegated mailbox access  
Improves audit readiness and access visibility  

---

### 👥 User & Account Monitoring

#### Inactive Users Report
Identifies dormant accounts  
Supports licence optimisation and security  

---

### 💻 Endpoint & Environment Maintenance

#### Device Cleanup Script (Intune)
Identifies stale or inactive devices  
Improves endpoint management and visibility  

---

### 🔑 Service Desk Automation

#### Password Reset Automation
Supports faster resolution of common user issues  
Improves service efficiency  

---

## 📌 Key Benefits

- reduces repetitive administrative tasks  
- improves consistency and accuracy  
- strengthens identity and access governance  
- enhances visibility across the environment  
- supports security and compliance efforts  

---

## 🔒 Security Considerations

- no real credentials or tenant data are included  
- sensitive information should be handled securely in production  
- scripts should follow least-privilege access principles  
- always test scripts in a non-production environment before use  

---

## 🚀 Future Improvements

- role-based automation logic  
- integration with approval workflows  
- enhanced reporting dashboards  
- automation of access reviews and governance processes  
- improved logging and monitoring  

---

## 📂 Repository Structure

```text
m365-powershell-automation-scripts/
│
├── onboarding/
├── offboarding/
├── licensing/
├── security/
├── reporting/
├── device-management/
├── utilities/
└── docs/

🤝 Contributions

This repository is part of my continuous learning and development in automation, identity, and modern workplace technologies.

👩‍💻 Author

Latifat Victor

💭 Philosophy

“Automation is not just about saving time - it’s about improving systems, reducing risk, and enabling better ways of working.”
