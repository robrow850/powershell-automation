#requires -Version 7.2
<# .SYNOPSIS
Simulate create/update/disable operations against local JSON, with WhatIf support.
No Graph writes are implemented; output is the proposed resulting state.
#>
[CmdletBinding(SupportsShouldProcess)]
param([Parameter(Mandatory)][string]$StatePath,[Parameter(Mandatory)][string]$ChangesPath)
$ErrorActionPreference='Stop'
Import-Module "$PSScriptRoot/../common/Lab.Common.psm1" -Force
$state=Read-LabJson $StatePath; $changes=Read-LabJson $ChangesPath
$index=@{}
foreach($u in $state.users) {
    Assert-LabFields $u @('id','displayName','accountEnabled','groups','licenses')
    if($index.ContainsKey($u.id)){throw 'Duplicate user id'}
    $index[$u.id]=$u
}
# Validate the entire proposed plan on a copy before showing any accepted results.
foreach($change in $changes) {
    Assert-LabFields $change @('action','id')
    switch($change.action) {
        'create' {
            if($index.ContainsKey($change.id)){throw 'User already exists'}
            Assert-LabFields $change @('displayName')
            $index[$change.id]=@{id=$change.id;displayName=$change.displayName;accountEnabled=$true;groups=@();licenses=@()}
        }
        'update' {if(-not $index.ContainsKey($change.id)){throw 'Unknown user'}}
        'disable' {if(-not $index.ContainsKey($change.id)){throw 'Unknown user'}; $index[$change.id].accountEnabled=$false}
        default {throw 'Action must be create, update or disable'}
    }
    foreach($field in @('displayName','groups','licenses')) {
        if($change.Contains($field)) {
            if($field -eq 'displayName' -and [string]::IsNullOrWhiteSpace($change[$field])){throw 'Display name required'}
            if($field -ne 'displayName' -and $change[$field] -isnot [array]){throw "$field must be an array"}
            $index[$change.id][$field]=$change[$field]
        }
    }
}
if($PSCmdlet.ShouldProcess('local simulation only','Emit proposed user lifecycle state')) {
    @{mode='simulation';users=@($index.Values | Sort-Object id)} | ConvertTo-Json -Depth 12
}
Write-LabEvent 'user-lifecycle' 'completed'
