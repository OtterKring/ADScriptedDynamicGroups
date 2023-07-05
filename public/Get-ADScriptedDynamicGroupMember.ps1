<#
.SYNOPSIS
Return the members of a given ScriptedDynamic AD Group

.DESCRIPTION
Return the members of a given ScriptedDynamic AD Group

.PARAMETER InputObject
An AD group object or an AD group's name or objectguid to identify the group to query

.EXAMPLE
Get-ADScriptedDynamicGroupMember 'myDynGroup'

.NOTES
2023-07-05 ... initial version by Maximilian Otter
#>
function Get-ADScriptedDynamicGroupMember {
    [CmdletBinding()]
    param (
        [Parameter( ValueFromPipeline )]
        [PSOBject[]]
        $InputObject
    )

    begin {
        $JD = [JSONDescription]::new()
    }

    process {

        Get-ADScriptedDynamicGroup $InputObject |
            Foreach-Object -Process {
                Get-ADGroupMember $_.ObjectGUID
            }
    }

}