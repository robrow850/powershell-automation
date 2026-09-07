# entra-id labs

Run from the repository root with PowerShell 7.2+.

## User lifecycle simulator

Create/update/disable proposed user records, group/license assignments, plan validation and ShouldProcess. Emits a simulated state only; no tenant writes.

```powershell
./entra-id/Invoke-UserLifecycle.ps1 -StatePath samples/lifecycle-state.json -ChangesPath samples/lifecycle-changes.json -WhatIf
```

Inputs and expected findings are documented in the root README. Run tests/Test-Labs.ps1 for offline validation.
