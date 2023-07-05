<#
.SYNOPSIS
Update the member list of a custom ScriptedDynamic group

.DESCRIPTION
Update the member list of a custom ScriptedDynamic group

.PARAMETER InputObject
Name(s), ObjectGuid(s) or AD object(s) of the group(s) to update

.EXAMPLE
Update-ADScriptedDynamicGroup

Will search Active Directory for groups with matching JSON information in the Description and update them all.

.EXAMPLE
Update-ADScriptedDynamicGroup -InputObject Finance_Consulants

Will check if a group named "Finance_Consulants" exists and if it holds the ScriptedDynamic info in the description field and update the member list according to the filter saved in the description field.

.EXAMPLE
Get-ADGroup Finance_Consulants | Update-ADScriptedDynamicGroup

Will use the ObjectGuid from the pipeline, query the info from the description field and, if usable, update the group's member list.

.NOTES
2023-05-03 ... initial version by Maximilian Otter
2023-05-04 ... added searchin by SearchBase and additional algorithm to get 5000+ group members (ADWS limits Get-ADGroupMember to 5000 by default)
2023-06-22 ... modulized the update code in several helper functions, added "update all" funcionality when called without parameters without or as the first element of a pipeline
2023-07-05 ... rewrite: combine names parameters to 1 InputObject, rewrite code using only one parameter
#>
function Update-ADScriptedDynamicGroupMembers {
    [CmdletBinding()]
    param (
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    begin {

        # if first cmd in (or without) pipeline and no parameters...
        if ( $MyInvocation.PipelinePosition -le 1 -and $PSBoundParameters.Count -eq 0 ) {
            Get-ADScriptedDynamicGroup |
                Where-Object {
                    process {
                        updateGroup -Group $_
                    }
                }
        } else {
            $JD = [JSONDescription]::new()
        }

    }

    process {

        foreach ( $obj in $InputObject ) {

            $filter = if ( $obj -as [guid] ) {
                "ObjectGUID -eq '$obj'"
            } elseif ( $obj.ObjectGUID ) {
                "ObjectGUID -eq '$($obj.ObjectGUID)'"
            } elseif ( $obj -is [string] ) {
                "Name -eq '$obj'"
            } elseif ( $obj.Name ) {
                "Name -eq '$($obj.Name)'"
            } else {
                Write-Warning ( "[{0}] cannot be used to query group")
            }

            if ( $filter ) {
                $filter = $filter + " -and Description -like '*$($JD.Prefix)*' -and Description -like '*$($JD.Postfix)*'"
                $g = Get-ADGroup -Filter $filter -Properties Description
                if ( $g ) {
                    updateGroup -Group $g
                } else {
                    Write-Warning ( "[{0}] does not resolve to a group" -f $filter )
                }
            }

        }

    }

}