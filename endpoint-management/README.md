# Endpoint Management (Intune)

Scripts for managing devices within Microsoft Intune.

## 📌 Purpose
Improves visibility and management of endpoint devices.

## 📂 Scripts Included
- Invoke-IntuneDeviceCleanup.ps1  

## ⚙️ Key Features
- Identification of stale devices  
- Device cleanup support  

## 🛠️ Requirements
- Microsoft Graph PowerShell SDK  
- Intune permissions  

## 🚀 Use Cases
- Device hygiene  
- Endpoint optimisation  
- Inventory cleanup  


## Invoke-IntuneDeviceCleanup.ps1

Identifies stale managed devices in Microsoft Intune and optionally retires them.

### Key outputs
- device name and user principal name
- operating system and OS version
- compliance state
- last sync date
- inactive days
- cleanup action taken

### Use case
Supports endpoint hygiene, device lifecycle governance, and cleanup of stale Intune-managed devices to improve visibility and reduce clutter.
