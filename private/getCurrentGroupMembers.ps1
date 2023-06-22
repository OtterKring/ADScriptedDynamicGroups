function getCurrentGroupMembers ( $Group ) {

    # query the current group members
    # if the group description says, the group hold more than 5000 members,
    # use a different approach to get the members to circumvent the default ADWS limit of 5000 objects
    # for Get-ADGroupMember

    if ( $GroupDescription.MemberCount -lt 5000 ) {
        ( Get-ADGroupMember $Group.ObjectGuid ).ObjectGuid | Sort-Object
    } else {
        if ( $GroupDescription.SearchBase.Count -gt 0 ) {
            $GroupDescription.SearchBase |
                ForEach-Object -Process { Get-ADUser -SearchBase $_ -Filter * -Properties MemberOf } |
                Where-Object { Process { $Group.DistinguishedName -in $_.MemberOf } } |
                Select-Object -ExpandProperty ObjectGuid |
                Sort-Object
        } else {
            Get-ADUser -Filter * -Properties MemberOf |
                Where-Object { Process { $Group.DistinguishedName -in $_.MemberOf } } |
                Select-Object -ExpandProperty ObjectGuid |
                Sort-Object
        }
    }

}