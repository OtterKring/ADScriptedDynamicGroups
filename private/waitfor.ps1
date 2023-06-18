<#
.SYNOPSIS
Wait for a scripted event to return a value for a given timespan

.DESCRIPTION
Waits for a scripted event to return a value for a given timespan, then returns the result (if any).

.PARAMETER ScriptBlock
A scriptblock object which should ultimately return something the function waits for. The scriptblock will be executed every second.

.PARAMETER TimeOut
A timespan object which defines the maximum time the function will try to get a result

.EXAMPLE
waitfor -ScriptBlock { ( Get-ADUser hugo ).Enabled } -TimeOut [timespan]::fromSeconds(10)

Runs (Get-ADUser hugo).Enabled every second until it is $true or the Timeout of 10 secods is reached

.NOTES
2023-05-03 ... initial version by Maximilian Otter
#>
function waitfor ( [scriptblock] $ScriptBlock, [timespan]$TimeOut ) {

    $sw = [System.Diagnostics.Stopwatch]::new()
    $sw.Start()
    
    $result = & $ScriptBlock
    while ( -not $result -and $sw.Elapsed -lt $TimeOut ) {
        $result = & $ScriptBlock
        Start-Sleep -Seconds 1
    }
    
    $result

}