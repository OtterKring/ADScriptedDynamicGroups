function getObsoleteGroupMembers ( [guid[]] $Current, [guid[]] $Target ) {

    # collect members which should not be included anymore
    if ( $Target.Count -gt 0 ) {
        foreach ( $guid in $Current ) {
            if ( [array]::BinarySearch( $Target, $guid ) -lt 0 ) { $guid }
        }
    } else {
        $Current
    }

}