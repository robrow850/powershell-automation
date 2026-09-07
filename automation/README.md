# automation labs

Run from the repository root with PowerShell 7.2+.

## Parallel framework

Runs sample integer jobs in bounded runspaces, retries simulated transient failures, emits structured success/failure records and shows parent progress. Not an arbitrary remote execution framework.

```powershell
./automation/Invoke-ParallelLab.ps1 -Items 1,2,3 -FailOnce
```

Inputs and expected findings are documented in the root README. Run tests/Test-Labs.ps1 for offline validation.
