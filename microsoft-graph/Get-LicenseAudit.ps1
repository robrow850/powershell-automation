#requires -Version 7.2
<# .SYNOPSIS
Audit normalized user/license/service-plan fixtures; emit CSV or HTML.
#>
[CmdletBinding()]
param([Parameter(Mandatory)][string]$InputPath,[ValidateSet('Csv','Html')][string]$Format='Csv')
$ErrorActionPreference='Stop'
Import-Module "$PSScriptRoot/../common/Lab.Common.psm1" -Force
$data=Read-LabJson $InputPath
$rows=@(foreach($u in $data) {
    Assert-LabFields $u @('id','enabled','licenses','servicePlans')
    $exceptions=@()
    if(-not $u.enabled -and $u.licenses.Count -gt 0){$exceptions+='DisabledWithLicense'}
    if($u.enabled -and $u.licenses.Count -eq 0){$exceptions+='NoLicense'}
    foreach($p in $u.servicePlans){if($p.status -ne 'Success'){$exceptions+='ServicePlan:'+ $p.name + ':' + $p.status}}
    # CSV formula escaping for arbitrary imported identifiers and plan names.
    $row=[ordered]@{id=$u.id;licenses=($u.licenses -join ';');servicePlans=($u.servicePlans.name -join ';');exceptions=($exceptions -join ';')}
    foreach($key in @($row.Keys)){if($Format -eq 'Csv' -and [string]$row[$key] -match '^\s*[=+@-]'){$row[$key]="'"+$row[$key]}}
    [pscustomobject]$row
})
if($Format -eq 'Html'){$rows | ConvertTo-Html -Title 'Sample license audit'}else{$rows | ConvertTo-Csv -NoTypeInformation}
Write-LabEvent 'license-audit' 'completed'
