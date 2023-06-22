function getDescribedGroupMembers {

    # query the users the group should have after updating, based on the membershiprule (and ev. SearchBase) from the group's description
    if ( $GroupDescription.SearchBase.Count -gt 0 ) {
        $GroupDescription.SearchBase |
            ForEach-Object -Process { Get-ADUser -SearchBase $_ -Filter $GroupDescription.MembershipRule } |
            Select-Object -ExpandProperty ObjectGuid |
            Sort-Object
    } else {
        Get-ADUser -Filter $GroupDescription.MembershipRule |
        Select-Object -ExpandProperty ObjectGuid |
        Sort-Object
    }

}