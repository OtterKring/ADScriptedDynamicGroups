function removeGroupMembers ( $Group, $Members ) {

    Write-Verbose ( "Removing {0} members from group {1}" -f $Members.Count, $Group.Name )
    
    Remove-ADGroupMember $existingGroup.ObjectGuid -Members $Members -Confirm:$false
    
    # reduce the MemberCount from the parent's GroupDescription variable by the amount of removed members
    $GroupDescription.MemberCount -= $Members.Count

}