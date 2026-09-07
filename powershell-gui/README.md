# powershell-gui labs

Run from the repository root with PowerShell 7.2+.

## WPF console

Windows-only fictional user grid with asynchronous PowerShell worker, UI timer, disabled refresh during work and cleanup. Syntax-checked on macOS; actual WPF behavior is not yet verified on Windows.

```powershell
pwsh -STA -File powershell-gui/Show-LabConsole.ps1
```

Inputs and expected findings are documented in the root README. Run tests/Test-Labs.ps1 for offline validation.

Manual Windows check: click Load sample users, confirm the window remains responsive, confirm two fictional rows appear, and close the window during a load to check worker cleanup. Actual execution and screenshots remain unverified.
