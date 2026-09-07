#requires -Version 7.2
<# .SYNOPSIS
Inspect normalized mailbox fixtures. No Exchange session or changes occur.
#>
[CmdletBinding()]
param([Parameter(Mandatory)][string]$InputPath,[string[]]$AcceptedDomains=@('example.com'))
$ErrorActionPreference='Stop'
Import-Module "$PSScriptRoot/../common/Lab.Common.psm1" -Force
$rows=@(foreach($m in (Read-LabJson $InputPath)) {
    Assert-LabFields $m @('id','type','forwarding','delegates','permissions')
    $findings=@()
    if($m.forwarding){
        try {$address=[Net.Mail.MailAddress]::new($m.forwarding); if($address.Host -notin $AcceptedDomains){$findings+='ExternalForwarding'}}
        catch {$findings+='InvalidForwardingAddress'}
    }
    if($m.delegates.Count -gt 0){$findings+='DelegatesRequireReview'}
    if($m.permissions -contains 'FullAccess'){$findings+='FullAccessRequiresReview'}
    if($m.type -eq 'Shared'){$findings+='SharedMailboxOwnershipReview'}
    [pscustomobject]@{id=$m.id;type=$m.type;delegates=@($m.delegates);permissions=@($m.permissions);findings=$findings}
})
ConvertTo-Json -InputObject $rows -Depth 10
Write-LabEvent 'mailbox-audit' 'completed'
