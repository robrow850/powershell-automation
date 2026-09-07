#requires -Version 7.2
Set-StrictMode -Version Latest
function Read-LabJson([string]$Path) {
    $options = @{AsHashtable=$true}
    if ((Get-Command ConvertFrom-Json).Parameters.ContainsKey('DateKind')) { $options.DateKind='String' }
    return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json @options
}
function Write-LabEvent([string]$Workflow, [string]$Status) {
    # Information stream keeps machine-readable success output separate.
    Write-Information (ConvertTo-Json -Compress @{event=$Status; workflow=$Workflow; time=[DateTimeOffset]::UtcNow.ToString('o')}) -InformationAction Continue
}
function Assert-LabFields($Record, [string[]]$Fields) {
    foreach ($field in $Fields) { if (-not $Record.Contains($field)) { throw "Missing field: $field" } }
}
Export-ModuleMember -Function Read-LabJson,Write-LabEvent,Assert-LabFields
