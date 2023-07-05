<#
.SYNOPSIS
Update the member list of a custom ScriptedDynamic group

.DESCRIPTION
Update the member list of a custom ScriptedDynamic group

.PARAMETER Name
Name of the group to update

.PARAMETER ObjectGuid
ObjectGuid of an existing group to update

.EXAMPLE
Update-ADScriptedDynamicGroup

Will search Active Directory for groups with matching JSON information in the Description and update them all.

.EXAMPLE
Update-ADScriptedDynamicGroup -Name Finance_Consulants

Will check if a group named "Finance_Consulants" exists and if it holds the ScriptedDynamic info in the description field and update the member list according to the filter saved in the description field.

.EXAMPLE
Get-ADGroup Finance_Consulants | Update-ADScriptedDynamicGroup

Will use the ObjectGuid from the pipeline, query the info from the description field and, if usable, update the group's member list.

.NOTES
2023-05-03 ... initial version by Maximilian Otter
2023-05-04 ... added searchin by SearchBase and additional algorithm to get 5000+ group members (ADWS limits Get-ADGroupMember to 5000 by default)
2023-06-22 ... modulized the update code in several helper functions, added "update all" funcionality when called without parameters without or as the first element of a pipeline
#>
function Update-ADScriptedDynamicGroupMembers {
    [CmdletBinding()]
    param (
        [Parameter( ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [string]
        $Name,

        [Parameter( ValueFromPipelineByPropertyName )]
        [guid]
        $ObjectGuid
    )

    begin {

        # if the function was called as the first command in a pipeline (or without any pipeline) and no parameter was provided, find all groups with this module's json information in the description
        # if ( $MyInvocation.PipelinePosition -eq 0 -and -not ( $Name -or $ObjectGuid ) ) {
            # $local:JD = [JSONDescription]::new()
            # $DynGroups = Get-ADGroup -Filter "Description -like '*$($JD.Prefix)*' -and Description -like '*$($JD.Postfix)*'" -Properties Description
            # Remove-Variable -Name JD -Scope Local
        #     $DynGroups
        # }

    }

    process {

        
        # preferrably find the group by ObjectGUID, use Name as a fallback.
        $existingGroup = if ( $ObjectGuid ) {
            Get-ADGroup -Filter "ObjectGUID -eq '$ObjectGuid'" -Properties Description
        } else {
            Get-ADGroup -Filter "Name -eq '$Name'" -Properties Description
        }

        # only proceed if a group with the give name or objectguid exists
        if ( $existingGroup ) {
            updateGroup -Group $existingGroup
        } else {
            Write-Error -Message ( "Group {0} does not exist." -f $existingGroup.Name ) -ErrorAction Stop
        }

    }

    end {

        # if the function was called without or as the first element of a pipeline without any parameters so it queried all groups with matching json information in the description. The Process section was left out in this case, so we must deal with the returned groups here.
        # if ( $DynGroups.Count -gt 0 ) {
        #     foreach ( $g in $DynGroups ) {
        #         updateGroup -Group $g
        #     }
        # }

        # if first cmd in (or without) pipeline and no parameters...
        if ( $MyInvocation.PipelinePosition -le 1 -and $PSBoundParameters.Count -eq 0 ) {
            Get-ADScriptedDynamicGroup |
                Where-Object {
                    process {
                        updateGroup -Group $_
                    }
                }
        }

    }

}