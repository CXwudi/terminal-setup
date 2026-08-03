# Scripts

## AI Tools Update Script

Contains scripts to update AI tools:

- [`ai-tools-update.ps1`](./ai-tools-update.ps1): Window side update script
- [`ai-tools-update.sh`](./ai-tools-update.sh): Linux side update script
- [`ai-tools-update.startup.ps1`](./ai-tools-update.startup.ps1): Windows side launcher script used by Task Scheduler

## Auto update on Windows

Action: Start a program

Program: `C:\Program Files\PowerShell\7\pwsh.exe`
Arguments: `-NoLogo -ExecutionPolicy Bypass -File "%USERPROFILE%\.local\bin\ai-tools-update.startup.ps1"`
