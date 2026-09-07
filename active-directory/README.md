# active-directory labs

Run from the repository root with PowerShell 7.2+.

## AD health report

Evaluates supplied DC reachability/replication/DNS evidence, stale-object candidates, lab password threshold and FSMO records. It does not collect live AD evidence.

```powershell
./active-directory/Get-AdHealthReport.ps1 -InputPath samples/ad-health.json
```

Inputs and expected findings are documented in the root README. Run tests/Test-Labs.ps1 for offline validation.

## Group membership analyzer

Traverses nested groups, flags cycles, privileged users, unresolved members and a depth limit. Privilege is supplied by fixtures, not discovered from a tenant.

```powershell
./active-directory/Get-GroupAnalysis.ps1 -InputPath samples/groups.json
```

Inputs and expected findings are documented in the root README. Run tests/Test-Labs.ps1 for offline validation.
