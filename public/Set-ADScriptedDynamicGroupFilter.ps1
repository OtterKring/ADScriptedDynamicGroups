<#
.SYNOPSIS
Set a new membershiprule in a ScriptedDynamic ADGroup's description json

.DESCRIPTION
Set a new membershiprule in a ScriptedDynamic ADGroup's description json and update the memberlist (if not opted out)

.PARAMETER InputObject
Name or ObjectGuid of the group to updated

.PARAMETER MembershipRule
New membershiprule. Must comply with Get-ADUser filter syntax.

.PARAMETER SearchBase
Array of OrganizationalUnits' DistinguishedNames to search users in. If omitted, all AD will be searched.

.PARAMETER DoNotUpdateMemberlist
Switch to opt out from updating the memberlist after changing the membershiprule

.EXAMPLE
Set-ADScriptedDynamicGroupFilter -Name ATHQ_Consultants -MembershipRule 'Enabled -eq "true" -and SamAccountName -like "c_*" -and extensionAttribute7 -eq "ATHQ"'

Updates the membershiprule string in the description json and the memberlist of the group

.NOTES
2023-05-03 ... initial version by Maximilian Otter
2024-05-04 ... added SearchBase
#>
function Set-ADScriptedDynamicGroupFilter {
    [CmdletBinding()]
    param (
        [Parameter( Mandatory )]
        [Alias( 'Name','ObjectGuid' )]
        [string]
        $InputObject,

        [Parameter( Mandatory )]
        [string]
        $MembershipRule,

        [Parameter()]
        [string[]]
        $SearchBase,

        [Parameter()]
        [switch]
        $DoNotUpdateMemberlist
    )

    $splat_GetADGroup = @{
        Filter = if ( $InputObject -as [guid] ) {
                "ObjectGuid -eq `"$InputObject`"" 
            } else {
                "Name -eq `"$InputObject`""
            }
        Properties = 'Description'
    }
    $existingGroup = Get-ADGroup @splat_GetADGroup
    

    if ( $existingGroup ) {

        # get Description data from json string and update rule and latestupdate
        $GroupDescription = [JSONDescription]$existingGroup.Description

        if ( $GroupDescription.Type -eq 'ScriptedDynamic' -and -not [string]::IsNullOrEmpty( $GroupDescription.MembershipRule ) ) {

            $GroupDescription.MembershipRule = $MembershipRule
            if ( $PSBoundParameters.ContainsKey('SearchBase') ) { $GroupDescription.SearchBase = $SearchBase }
            $GroupDescription.LatestUpdate = ( [datetime]::now ).ToString('o')

            # replace description string with new data and update group
            Write-Verbose ( "Setting membershiprule [{0}] on group [{1}]" -f $MembershipRule, $existingGroup.Name )
            Set-ADGroup $existingGroup.ObjectGuid -Description $GroupDescription

            # update memberlist (if not opted out) after updating membershiprule
            if ( -not $DoNotUpdateMemberlist ) {
                Write-Verbose ( "Updating memberlist on group [{0}]" -f $existingGroup.Name )
                Update-ADScriptedDynamicGroupMembers -ObjectGuid $existingGroup.ObjectGuid
            }

        } else {
            Write-Error -Message ( "Group {0}'s description json does not show type `"ScriptedDynamic`" or does not contain a membershiprule." -f $existingGroup.Name ) -ErrorAction Stop
        }

    } else {
        Write-Error -Message ( "Group [{0}] does not exist." -f $InputObject ) -ErrorAction Stop
    }

}