#requires -Version 7.2
<# .SYNOPSIS
Bounded runspace jobs with retry, structured results and parent progress.
Jobs square sample integers; FailOnce demonstrates retry without external actions.
#>
[CmdletBinding()]
param([int[]]$Items=@(1,2,3),[ValidateRange(1,16)][int]$ThrottleLimit=4,[ValidateRange(0,5)][int]$Retries=2,[switch]$FailOnce)
$ErrorActionPreference='Stop'
$retryCount=$Retries; $shouldFail=[bool]$FailOnce
$job=$Items | ForEach-Object -Parallel {
    $value=$_; $attempt=0
    while($true){
        try {
            $attempt++
            if($using:shouldFail -and $attempt -eq 1){throw 'Simulated transient failure'}
            [pscustomobject]@{item=$value;result=([long]$value*$value);attempts=$attempt;status='Success';error=$null}
            break
        }catch {
            if($attempt -gt $using:retryCount){[pscustomobject]@{item=$value;result=$null;attempts=$attempt;status='Failed';error='Sample operation failed'};break}
            Start-Sleep -Milliseconds (50*$attempt)
        }
    }
} -ThrottleLimit $ThrottleLimit -AsJob
try {
    while($job.State -in @('Running','NotStarted')) {
        $done=@($job.ChildJobs | Where-Object State -in @('Completed','Failed','Stopped')).Count
        Write-Progress -Activity 'Sample parallel jobs' -Status "$done completed" -PercentComplete (100*$done/[Math]::Max(1,$Items.Count))
        $null=Wait-Job $job -Timeout 1
    }
    $results=@(Receive-Job $job -ErrorAction Stop | Sort-Object item)
    ConvertTo-Json -InputObject $results -Depth 8
}finally{Write-Progress -Activity 'Sample parallel jobs' -Completed; Remove-Job $job -Force}
