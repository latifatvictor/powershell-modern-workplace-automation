# PowerShell Modern Workplace Automation

This repository contains practical PowerShell scripts for **Microsoft 365, Entra ID, and Intune** to support Modern Workplace administration, identity and endpoint security, and operational reporting.

The goal is simple: reduce manual effort, improve consistency, and provide clear operational visibility across enterprise environments.

---

## What you’ll find here

- Identity and access automation (Entra ID)
- Intune device compliance and reporting
- Operational checks and export scripts
- Admin and security hygiene scripts
- Reusable script patterns and safe publishing practices

---

## Repository structure

/scripts

Ready-to-run scripts

/docs

Usage notes and examples

/output

Local outputs (ignored in Git)


---

## How to use

1. Review the script header for required permissions and modules  
2. Run scripts in PowerShell 7 where possible  
3. Always test in a non-production environment first  

---

## Safe publishing note

Do not commit exports from production tenants (CSV/JSON) that contain real user, device, or tenant data.  
This repo is designed to keep scripts public, while keeping outputs private.

---

## Scripts

- `intune-device-compliance-report.ps1` Generate a CSV report of Intune managed devices (compliance, encryption, OS, last sync)

More scripts will be added as this repo grows.

---
