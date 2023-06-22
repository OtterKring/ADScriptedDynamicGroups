function getNewGroupMembers ( [guid[]] $Current, [guid[]] $Target ) {

    # collect members not YET on the memberlist
    if ( $Current.Count -gt 0 ) {
        foreach ( $guid in $Target ) {
            if ( [array]::BinarySearch( $Current, $guid) -lt 0 ) { $guid }
        }
    } else {
        $Target
    }

}