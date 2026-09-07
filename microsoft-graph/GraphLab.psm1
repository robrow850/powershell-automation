#requires -Version 7.2
<# Read-only Graph wrapper. Authentication accepts a short-lived SecureString token
obtained through authorized identity tooling; this module never stores credentials. #>
function Get-GraphLabUsers {
    [CmdletBinding(DefaultParameterSetName='Fixture')]
    param([Parameter(Mandatory,ParameterSetName='Fixture')][string]$FixturePath,
          [Parameter(Mandatory,ParameterSetName='Live')][securestring]$AccessToken,
          [ValidateRange(1,1000)][int]$MaxPages=100)
    $ErrorActionPreference='Stop'
    if($PSCmdlet.ParameterSetName -eq 'Fixture') {
        foreach($page in (Get-Content -LiteralPath $FixturePath -Raw | ConvertFrom-Json)){foreach($u in $page.value){$u}}
        return
    }
    $next='https://graph.microsoft.com/v1.0/users?$select=id,displayName,userPrincipalName'
    $seen=[Collections.Generic.HashSet[string]]::new()
    while($next){
        $uri=[uri]$next
        if($uri.Scheme -ne 'https' -or $uri.Host -ne 'graph.microsoft.com' -or $uri.Port -ne 443 -or $uri.UserInfo -or -not $uri.AbsolutePath.StartsWith('/v1.0/')){throw 'Untrusted Graph pagination URL'}
        if(-not $seen.Add($next) -or $seen.Count -gt $MaxPages){throw 'Repeated page or pagination limit'}
        $page=$null
        for($attempt=0;$attempt -le 2;$attempt++) {
            try {$page=Invoke-RestMethod -Uri $next -Authentication Bearer -Token $AccessToken -Method Get -MaximumRedirection 0 -TimeoutSec 30;break}
            catch {
                $status=if($_.Exception.Response){[int]$_.Exception.Response.StatusCode}else{0}
                if($status -notin @(429,502,503,504) -or $attempt -eq 2){throw "Graph GET failed (status $status)"}
                Start-Sleep -Seconds ([Math]::Pow(2,$attempt))
            }
        }
        if($null -eq $page.value){throw 'Missing Graph value array'}
        foreach($u in $page.value){$u}
        $next=$page.'@odata.nextLink'
    }
}
Export-ModuleMember -Function Get-GraphLabUsers
