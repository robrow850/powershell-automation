#requires -Version 7.2
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
function Assert($Condition,[string]$Message){if(-not $Condition){throw $Message}}
$errors=$null;$tokens=$null
Get-ChildItem $root -Recurse -Include *.ps1,*.psm1 | ForEach-Object {
 $null=[Management.Automation.Language.Parser]::ParseFile($_.FullName,[ref]$tokens,[ref]$errors)
 Assert ($errors.Count -eq 0) "Parse error in $($_.Name): $errors"
}
$state="$root/samples/lifecycle-state.json";$changes="$root/samples/lifecycle-changes.json"
$before=(Get-FileHash $state).Hash
$result=& "$root/entra-id/Invoke-UserLifecycle.ps1" -StatePath $state -ChangesPath $changes -Confirm:$false 6>$null | ConvertFrom-Json
Assert ($result.users.Count -eq 2) 'Create workflow failed'
Assert (-not ($result.users | Where-Object id -eq 'sample-1').accountEnabled) 'Disable failed'
Assert (($result.users | Where-Object id -eq 'sample-1').groups[0] -eq 'sample-readers') 'Group update failed'
$null=& "$root/entra-id/Invoke-UserLifecycle.ps1" -StatePath $state -ChangesPath $changes -WhatIf 6>$null
Assert ((Get-FileHash $state).Hash -eq $before) 'Simulation mutated fixture'
$html=& "$root/active-directory/Get-AdHealthReport.ps1" -InputPath "$root/samples/ad-health.json" 6>$null
Assert (($html -join '') -match 'Fail') 'Health failure not reported'
Assert (($html -join '') -match 'Unknown') 'Unknown health evidence lost'
$license=& "$root/microsoft-graph/Get-LicenseAudit.ps1" -InputPath "$root/samples/licenses.json" 6>$null | ConvertFrom-Csv
Assert ($license[0].exceptions -match 'DisabledWithLicense') 'License exception missing'
Assert ($license[1].exceptions -eq 'NoLicense') 'Unlicensed user missing'
$groups=& "$root/active-directory/Get-GroupAnalysis.ps1" -InputPath "$root/samples/groups.json" 6>$null | ConvertFrom-Json
Assert (@($groups | Where-Object finding -eq 'Cycle').Count -gt 0) 'Cycle missing'
Assert (@($groups | Where-Object finding -eq 'PrivilegedUser').Count -gt 0) 'Privileged user missing'
Assert (@($groups | Where-Object finding -eq 'Unresolved').Count -gt 0) 'Missing reference not reported'
$mail=& "$root/exchange-online/Get-MailboxAudit.ps1" -InputPath "$root/samples/mailboxes.json" 6>$null | ConvertFrom-Json
Assert ($mail[0].findings -contains 'ExternalForwarding') 'External forwarding missing'
$jobs=& "$root/automation/Invoke-ParallelLab.ps1" -Items @(2,3) -FailOnce | ConvertFrom-Json
Assert ($jobs[0].result -eq 4 -and $jobs[1].result -eq 9) 'Parallel output wrong'
Assert ($jobs[0].attempts -eq 2) 'Retry did not run'
$failed=& "$root/automation/Invoke-ParallelLab.ps1" -Items @(2) -FailOnce -Retries 0 | ConvertFrom-Json
Assert ($failed[0].status -eq 'Failed') 'Exhausted retry not reported'
Import-Module "$root/microsoft-graph/GraphLab.psm1" -Force
Assert (@(Get-GraphLabUsers -FixturePath "$root/samples/graph-pages.json").Count -eq 2) 'Graph fixture paging wrong'
if(-not $IsWindows){
 $caught=$false;try{& "$root/powershell-gui/Show-LabConsole.ps1"}catch{$caught=$_.Exception.Message -like '*requires Windows*'}
 Assert $caught 'WPF platform guard failed'
}
'PASS: syntax and all offline PowerShell lab assertions. WPF UI and live APIs not exercised.'
