# microsoft-graph labs

Run from the repository root with PowerShell 7.2+.

## M365 license auditor

Examines normalized license and service-plan assignments; CSV and HTML outputs flag disabled licensed users, enabled unlicensed users and non-successful plans. These are review candidates, not license-policy conclusions.

```powershell
./microsoft-graph/Get-LicenseAudit.ps1 -InputPath samples/licenses.json
```

Inputs and expected findings are documented in the root README. Run tests/Test-Labs.ps1 for offline validation.

## Graph module

Import GraphLab.psm1 and call Get-GraphLabUsers -FixturePath samples/graph-pages.json. Live mode accepts a SecureString AccessToken and performs only bounded GET requests to the global Graph v1.0 host. Authentication acquisition/refresh and tenant validation remain external prerequisites.
