<#
.SYNOPSIS
Create a new Active Directory group, defining it as "ScriptedDynamic" group in its JSON encapsulated description

.DESCRIPTION
Create a new Active Directory group, defining it as "ScriptedDynamic" group in its JSON encapsulated description

.PARAMETER Name
Name of the Active Directory Group. Will be used as DisplayName and SamAccountName as well.

.PARAMETER Path
Target path of the group. May be presented as DistinguishedName or CanonicalName.

.PARAMETER MembershipRule
Filter to be used for adding members. Must comply with standard Get-ADUser filter syntax, e.g. 'SamAccountName -like "c_*"'

.PARAMETER SearchBase
Array of OrganizationalUnits' DistinguishedNames to search users for. If omitted, users will be searched for in all AD.

.PARAMETER GroupScope
GroupScope as used in Active Directory. Allowed values are Universal, Global and Local. Default is Universal.

.PARAMETER GroupCategory
GroupCategory as used in Active Directory. Allowed values are Distribution and Security. Default is Security

.PARAMETER TimeOutinSeconds
Seconds to wait for the new group to appear in Active Directory after creation. Default = 10

.EXAMPLE
New-AGRADScriptedDynamicGroup -Name ATHQ_Consultants -Path 'OU=Groups,OU=ATAB,OU=AT,DC=agrana,DC=net' -MembershipRule 'Enabled -eq true -and SamAccountName -like "c_*"'

Will created the universal security group ATHQ_Consultants at agrana.net/AT/ATAB/Groups and add all enabled UserAccounts with a SamAccountName starting with 'c_' to the group.

.NOTES
2023-05-03 ... initial version by Maximilian Otter
2023-05-04 ... added SearchBase
#>
function New-ADScriptedDynamicGroup {
    [CmdletBinding()]
    param (
        [Parameter( Mandatory )]
        [string]
        $Name,

        [Parameter( Mandatory )]
        [DistinguishedName]
        $Path,

        [Parameter( Mandatory )]
        [string]
        $MembershipRule,

        [Parameter()]
        [string[]]
        $SearchBase,

        [Parameter()]
        [ValidateSet( 'Universal','Global','Local' )]
        [string]
        $GroupScope = 'Universal',

        [Parameter()]
        [ValidateSet( 'Distribution','Security' )]
        [string]
        $GroupCategory = 'Security',

        [Parameter()]
        [byte]
        $TimeOutinSeconds = 10
    )

    # get any existing group with the desired name
    $existingGroup = Get-ADGroup -Filter "Name -eq '$Name'"

    # only continue, if there is no other group with this name
    if ( -not $existingGroup ) {

        # prepare group parameters
        $splat = @{
            Path = $Path
            Name = $Name
            DisplayName = $Name
            GroupCategory = $GroupCategory
            GroupScope = $GroupScope
            SamAccountName = $Name
            # The description field is filled with meta-data as json, to be able to identify the group
            # as ScriptedDynamic and the filter, with which it was created
            Description = [JSONDescription][ordered]@{
                Type = 'ScriptedDynamic'
                MembershipRule = $MembershipRule
                SearchBase = $SearchBase
                MemberCount = 0
                LatestUpdate = ( [datetime]::now ).ToString('o')
            }
        }

        # create the group
        Write-Verbose ( "Creating AD Group [{0}] in OU [{1}]" -f $splat.Name, $splat.Path )
        New-ADGroup @splat

        # wait for the group to appear on Active Directory
        $NewGroup = waitfor -ScriptBlock { Get-ADGroup -Filter "Name -eq '$Name'" } -TimeOut ( [timespan]::fromSeconds( $TimeOutinSeconds ) )

        # if the group appeared in time in Active Directory, add Members
        if ( $NewGroup ) {
            Write-Verbose ( "Adding Members matching filter [{0}] to group [{1}]" -f $MembershipRule, $NewGroup.Name )
            Update-ADScriptedDynamicGroupMembers -ObjectGuid $NewGroup.ObjectGuid
        } else {
            Write-Warning "The group did not appear in Active Directory within the given timeout of $TimeOutinSeconds seconds."
        }

    } else {
        Write-Error -Message 'Group exists.' -ErrorAction Stop
    }

}