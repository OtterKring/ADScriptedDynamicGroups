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
Update-AGRADScriptedDynamicGroup -Name ATHQ_Consultants

Will check if a group named "ATHQ_Consultants" exists and if it holds the ScriptedDynamic info in the description field and update the member list according to the filter saved in the description field.

.EXAMPLE
Get-ADGroup ATHQ_Consultants | Update-AGRADScriptedDynamicGroup

Will use the ObjectGuid from the pipeline, query the info from the description field and, if usable, update the group's member list.

.NOTES
2023-05-03 ... initial version by Maximilian Otter
2023-05-04 ... added searchin by SearchBase and additional algorithm to get 5000+ group members (ADWS limits Get-ADGroupMember to 5000 by default)
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

    process {

        # preferrably find the group by ObjectGUID, use Name as a fallback.
        $existingGroup = if ( $ObjectGuid ) {
            Get-ADGroup -Filter "ObjectGUID -eq '$ObjectGuid'" -Properties Description
        } else {
            Get-ADGroup -Filter "Name -eq '$Name'" -Properties Description
        }

        # only proceed if a group with the give name or objectguid exists
        if ( $existingGroup ) {

            # extract the group-info json from the description, keeping in mind that someone might have added additional text before or behind
            $GroupDescription = [JSONDescription]$existingGroup.Description

            # only proceed, if the GroupDescription contains the field "Type=ScriptedDynamic" and "MembershipRule" is not empty
            if ( $GroupDescription.Type -eq 'ScriptedDynamic' -and -not [string]::IsNullOrEmpty( $GroupDescription.MembershipRule ) ) {

                # query the current group members
                # if the group description says, the group hold more than 5000 members,
                # use a different approach to get the members to circumvent the default ADWS limit of 5000 objects
                # for Get-ADGroupMember
                $CurrentGroupMembers = if ( $GroupDescription.MemberCount -lt 5000 ) {
                        ( Get-ADGroupMember $existingGroup.ObjectGuid ).ObjectGuid | Sort-Object
                    } else {
                        if ( $GroupDescription.SearchBase.Count -gt 0 ) {
                            $GroupDescription.SearchBase |
                                ForEach-Object -Process { Get-ADUser -SearchBase $_ -Filter * -Properties MemberOf } |
                                Where-Object { Process { $existingGroup.DistinguishedName -in $_.MemberOf } } |
                                Select-Object -ExpandProperty ObjectGuid |
                                Sort-Object
                        } else {
                            Get-ADUser -Filter * -Properties MemberOf |
                                Where-Object { Process { $existingGroup.DistinguishedName -in $_.MemberOf } } |
                                Select-Object -ExpandProperty ObjectGuid |
                                Sort-Object
                        }
                    }
                # query the users the group should have after updating, based on the membershiprule from the group's description
                $TargetGroupMembers = if ( $GroupDescription.SearchBase.Count -gt 0 ) {
                        ( $GroupDescription.SearchBase |
                            ForEach-Object -Process { Get-ADUser -SearchBase $_ -Filter $GroupDescription.MembershipRule } ).ObjectGuid | Sort-Object
                    } else {
                        ( Get-ADUser -Filter $GroupDescription.MembershipRule ).ObjectGuid | Sort-Object
                    }

                # collect members which should not be included anymore
                $Members2Remove = if ( $TargetGroupMembers.Count -gt 0 ) {
                        foreach ( $guid in $CurrentGroupMembers ) {
                            if ( [array]::BinarySearch( $TargetGroupMembers, $guid ) -lt 0 ) { $guid }
                        }
                    } else {
                        $CurrentGroupMembers
                    }
                # collect members not YET on the memberlist
                $Members2Add = if ( $CurrentGroupMembers.Count -gt 0 ) {
                        foreach ( $guid in $TargetGroupMembers ) {
                            if ( [array]::BinarySearch( $CurrentGroupMembers, $guid) -lt 0 ) { $guid }
                        }
                    } else {
                        $TargetGroupMembers
                    }
                
                # eventually remove members not matching the rule anymore
                if ( $Members2Remove.Count -gt 0 ) {
                    Write-Verbose ( "Removing {0} members from group {1}" -f $Members2Remove.Count, $existingGroup.Name )
                    Remove-ADGroupMember $existingGroup.ObjectGuid -Members $Members2Remove -Confirm:$false
                    $GroupDescription.MemberCount -= $Members2Remove.Count
                    $modified = $true
                }

                # eventually add new members
                if ( $Members2Add.Count -gt 0 ) {
                    Write-Verbose ( "Adding {0} members to group {1}" -f $Members2Add.Count, $existingGroup.Name )
                    Add-ADGroupMember $existingGroup.ObjectGuid -Members $Members2Add -Confirm:$false
                    $GroupDescription.MemberCount += $Members2Add.Count
                    $modified = $true
                }

                # update the LatestUpdate timestamp if members where added or removed
                if ( $modified ) {
                    $GroupDescription.LatestUpdate = ( [datetime]::now ).ToString('o')
                    Set-ADGroup $existingGroup.ObjectGuid -Description $GroupDescription -Confirm:$false
                }

            } else {
                Write-Error -Message ( "Group {0}'s description json does not show type `"ScriptedDynamic`" or does not contain a membershiprule." -f $existingGroup.Name ) -ErrorAction Stop
            }

        } else {
            Write-Error -Message ( "Group {0} does not exist." -f $existingGroup.Name ) -ErrorAction Stop
        }

    }

}