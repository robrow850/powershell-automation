#requires -Version 7.2
<# .SYNOPSIS
Evaluate normalized AD health evidence. This is an offline evaluator, not a DC collector.
#>
[CmdletBinding()]
param([Parameter(Mandatory)][string]$InputPath)
$ErrorActionPreference='Stop'
Import-Module "$PSScriptRoot/../common/Lab.Common.psm1" -Force
$data=Read-LabJson $InputPath
$rows=@(foreach($dc in $data.domainControllers) {
    foreach($check in @('reachable','replicationHealthy','dnsHealthy')) {
        $status=if(-not $dc.Contains($check) -or $null -eq $dc[$check]){'Unknown'} elseif($dc[$check] -isnot [bool]){throw 'Health evidence must be boolean or null'} elseif($dc[$check]){'Pass'}else{'Fail'}
        [pscustomobject]@{target=$dc.name;check=$check;status=$status}
    }
}
foreach($item in $data.staleObjects){[pscustomobject]@{target=$item.id;check='staleObjectCandidate';status='Review'}}
[pscustomobject]@{target='domain';check='minimumPasswordLength';status=if($data.passwordPolicy.minimumLength -ge 14){'Pass'}else{'Review'}}
foreach($role in @('SchemaMaster','DomainNamingMaster','PDCEmulator','RIDMaster','InfrastructureMaster')) {
    [pscustomobject]@{target='domain';check=$role;status=if($data.fsmo[$role]){'Recorded'}else{'Unknown'}}
})
# ConvertTo-Html encodes cell text. The policy threshold is a lab convention.
$rows | ConvertTo-Html -Title 'Sample AD health evidence' -PreContent '<h1>AD health evidence — offline lab</h1>'
Write-LabEvent 'ad-health' 'completed'
