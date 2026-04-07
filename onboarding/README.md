# 👤 Microsoft 365 User Onboarding Automation

PowerShell-based automation for onboarding users in Microsoft 365 and Microsoft Entra ID.

---

## 🚀 Overview

This solution automates the end-to-end onboarding process for new users, including:

- user account creation  
- licence assignment  
- group membership configuration  
- usage location setup  
- logging and audit tracking  

It is designed to **reduce manual effort, improve consistency, and support a structured Joiner (JML) process**.

---

## 🧠 Problem Statement

In many organisations, onboarding is:

- manual and time-consuming  
- inconsistent across teams  
- prone to human error  
- difficult to track and audit  

This often leads to:
- delays in user access  
- incorrect permissions  
- security and compliance risks  

---

## 💡 Solution

This script automates onboarding using PowerShell and Microsoft Graph by:

1. reading user data from a structured CSV file  
2. creating user accounts in Microsoft Entra ID  
3. assigning Microsoft 365 licences  
4. adding users to predefined groups  
5. logging all actions for traceability  

---

## ⚙️ Key Features

- ✔ Bulk user onboarding from CSV  
- ✔ Automated licence assignment  
- ✔ Group membership configuration  
- ✔ Built-in error handling  
- ✔ Logging for audit and troubleshooting  
- ✔ Idempotent checks (skips existing users)  

---

## 🛠️ Technologies Used

- PowerShell  
- Microsoft Graph PowerShell SDK  
- Microsoft Entra ID  
- Microsoft 365  

---

## 📂 Input File (CSV Structure)

The script expects a CSV file with the following fields:

| Field | Description |
|------|-------------|
| FirstName | User's first name |
| LastName | User's last name |
| DisplayName | Full display name |
| UserPrincipalName | User login (UPN) |
| MailNickname | Alias |
| Password | Initial password |
| Department | Department name |
| JobTitle | User role |
| UsageLocation | Country code (e.g. GB) |
| LicenseSkuPartNumber | Licence type (e.g. SPE_E3) |
| GroupIds | Group IDs (semicolon separated) |

---

## ▶️ How It Works

1. Connects to Microsoft Graph  
2. Imports user data from CSV  
3. Checks if user already exists  
4. Creates user account  
5. Assigns licence  
6. Adds user to groups  
7. Writes results to log file  

---

## 📊 Output

- Success and failure logs stored in a CSV file  
- Console output showing progress and status  

---

## 🚀 Example Usage

```powershell
.\New-M365UserOnboarding.ps1 -CsvPath ".\sample-users.csv"
