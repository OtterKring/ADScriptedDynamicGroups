function addGroupMembers ( $Group, $Members ) {

    Write-Verbose ( "Adding {0} members to group {1}" -f $Members.Count, $Group.Name )

    Add-ADGroupMember $Group.ObjectGuid -Members $Members -Confirm:$false

    # increase MemberCound from the parent's GroupDescription by the number of added users
    $GroupDescription.MemberCount += $Members.Count

}