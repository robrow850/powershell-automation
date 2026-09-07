#requires -Version 7.2
<# .SYNOPSIS
Traverse normalized group graphs, detect cycles and unresolved references.
#>
[CmdletBinding()]
param([Parameter(Mandatory)][string]$InputPath)
$ErrorActionPreference='Stop'
Import-Module "$PSScriptRoot/../common/Lab.Common.psm1" -Force
$data=Read-LabJson $InputPath
$groups=@{}; $users=@{}
foreach($g in $data.groups){if($groups.ContainsKey($g.id)){throw 'Duplicate group'};$groups[$g.id]=$g}
foreach($u in $data.users){if($users.ContainsKey($u.id) -or $groups.ContainsKey($u.id)){throw 'Duplicate/ambiguous identity'};$users[$u.id]=$u}
function Walk-Group([string]$Root,[string]$Id,[string[]]$Trail) {
    if($Id -in $Trail){return [pscustomobject]@{root=$Root;member=$Id;finding='Cycle';path=($Trail+$Id -join ' -> ')}}
    if($Trail.Count -ge 50){return [pscustomobject]@{root=$Root;member=$Id;finding='DepthLimit';path=($Trail -join ' -> ')}}
    foreach($member in $groups[$Id].members){
        if($groups.ContainsKey($member)){Walk-Group $Root $member ($Trail+$Id)}
        elseif($users.ContainsKey($member)) {
            [pscustomobject]@{root=$Root;member=$member;finding=if($users[$member].privileged){'PrivilegedUser'}else{'User'};path=($Trail+$Id+$member -join ' -> ')}
        }else{[pscustomobject]@{root=$Root;member=$member;finding='Unresolved';path=($Trail+$Id+$member -join ' -> ')}}
    }
}
$rows=@(foreach($id in ($groups.Keys | Sort-Object)){Walk-Group $id $id @()})
ConvertTo-Json -InputObject $rows -Depth 10
Write-LabEvent 'group-analysis' 'completed'
