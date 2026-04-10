
---

# 🏆 3. `docs/usage-guidelines.md`

```markdown id="use001"
# Usage Guidelines

## 📌 Overview

This document provides best practices for using the PowerShell automation scripts in this repository.

---

## 🚀 General Usage Flow

1. Review script purpose and requirements  
2. Ensure prerequisites are met  
3. Prepare input data (if required)  
4. Run script in a test environment  
5. Review output and logs  
6. Execute in production if validated  

---

## ⚙️ Execution Best Practices

- Run scripts using least-privileged accounts  
- Execute scripts in PowerShell 7 where possible  
- Use verbose output for troubleshooting  
- Always review logs after execution  

---

## 📂 File Handling

- Store reports in designated `/reports/` folders  
- Store logs in `/logs/` folders  
- Use sample data for testing  
- Avoid committing sensitive data to GitHub  

---

## 🔐 Security Guidelines

- Do not hardcode passwords  
- Use secure credential storage where possible  
- Avoid exposing tenant-specific information  
- Validate user inputs before execution  

---

## ⚠️ Operational Safety

- Scripts that perform actions (e.g. offboarding, cleanup) should:
  - be tested first  
  - be reviewed before execution  
  - include confirmation steps if used in production  

- Use **report-only mode** where available before enabling actions  

---

## 📊 Logging and Monitoring

- Always review output logs  
- Investigate failed entries  
- Maintain logs for audit purposes  

---

## 🔄 Change Management

When updating scripts:

- document changes clearly  
- test thoroughly  
- version control updates  
- communicate impact if used in production  

---

## 🚫 What NOT to Do

- Do not run scripts blindly in production  
- Do not use real passwords in CSV files  
- Do not ignore error messages  
- Do not assign excessive permissions  

---

## 💭 Summary

Following these guidelines ensures safe, secure, and effective use of automation scripts while maintaining governance and operational best practices.
