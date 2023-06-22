function updateGroup ( $Group )  {

    # extract the group-info json from the description, keeping in mind that someone might have added additional text before or behind (the class takes care about this)
    $GroupDescription = [JSONDescription]$Group.Description

    # only proceed, if the GroupDescription contains the field "Type=ScriptedDynamic" and "MembershipRule" is not empty
    if ( $GroupDescription.Type -eq 'ScriptedDynamic' -and -not [string]::IsNullOrEmpty( $GroupDescription.MembershipRule ) ) {

        # query the current group members
        $CurrentGroupMembers = getCurrentGroupMembers -Group $Group

        # query the users the group should have after updating, based on the membershiprule from the group's description
        $TargetGroupMembers = getDescribedGroupMembers

        # collect members which should not be included anymore
        $Members2Remove = getObsoleteGroupMembers -Current $CurrentGroupMembers -Target $TargetGroupMembers

        # collect members not YET on the memberlist
        $Members2Add = getNewGroupMembers -Current $CurrentGroupMembers -Target $TargetGroupMembers
        
        # eventually remove members not matching the rule anymore
        if ( $Members2Remove.Count -gt 0 ) {
            removeGroupMembers -Group $Group -Members $Members2Remove
            $modified = $true
        }

        # eventually add new members
        if ( $Members2Add.Count -gt 0 ) {
            addGroupMembers -Group $Group -Members $Members2Add
            $modified = $true
        }

        # update the LatestUpdate timestamp if members where added or removed
        if ( $modified ) {
            $GroupDescription.LatestUpdate = ( [datetime]::now ).ToString('o')
            Set-ADGroup $Group.ObjectGuid -Description $GroupDescription -Confirm:$false
        }

    } else {
        Write-Error -Message ( "Group {0}'s description json does not show type `"ScriptedDynamic`" or does not contain a membershiprule." -f $Group.Name ) -ErrorAction Stop
    }

}