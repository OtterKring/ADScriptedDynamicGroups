# helper class to allow DistinguishedNames (with or without CN) and CanonicalNames as $Path for the groups target OU
# 2023-05-03 ... initial version by Maximilian Otter
class DistinguishedName {

    hidden [string] $Value

    DistinguishedName ( [string]$Value ) {
        if ( [DistinguishedName]::isDN( $Value ) ) {
            $this.Value = [DistinguishedName]::trimCN( $Value )
        } elseif ( [DistinguishedName]::isCN( $Value ) ) {
            $this.Value = [DistinguishedName]::convertfromCN( $Value )
        } else {
            Throw 'Input value is not a valid Organizational Unit path format.'
        }
    }

    hidden [string] ToString () {
        return $this.Value
    }

    static hidden [string] trimCN ( [string]$Value ) {
        if ( $Value -like 'CN=*' ) {
            $commaindex = $Value.IndexOf(',') + 1
            $Output = $Value.Substring( $commaindex, $Value.Length - $commaindex )
        } else {
            $Output = $Value
        }
        return $Output
    }

    static hidden [bool] isDN ( [string]$Value ) {
        return $Value -match '^(OU\=.+?,)*(DC\=.{2,},)+DC\=.{2,}$'
    }

    static hidden [bool] isCN ( [string]$Value ) {
        return $Value -match '^(\w{2,}\.)+\w{2,}((\\|/)\w+)*'
    }

    static hidden [string] convertfromCN ( [string]$Value ) {
        $ValueParts = $Value -split '/|\\'
        $DC = $ValueParts[0] -split '\.'
        $DC = 'DC=' + ( $DC -join ',DC=' )
        return 'OU=' + ( $ValueParts[ ($ValueParts.Count-2) .. 1 ] -join ',OU=' ) + ',' + $DC
    }
 
}

# helper class to ensure proper handling of JSON data in description
# 2023-05-04 ... initial version by Maximilian Otter
class JSONDescription {

    [string] $Type
    [string] $MembershipRule
    [string[]] $SearchBase
    [UInt32] $MemberCount
    [datetime] $LatestUpdate

    hidden [string] $Prefix = 'JSON'
    hidden [string] $Postfix = 'NOSJ'
    hidden [string] $PrependingText
    hidden [string] $TrailingText
    

    JSONDescription () {}

    JSONDescription ( [string]$Value ) {

        try {
            $obj = ConvertFrom-Json -InputObject $this.Parse( $Value )
        } catch {
            Throw 'Could not extract JSON data from Description string'
        }
        $this.Init( $obj )

    }

    JSONDescription ( [pscustomobject]$Value ) {

        $this.Init( $Value )

    }

    hidden [void] Init ( [pscustomobject]$Value ) {

        $Properties = ( Get-Member -InputObject $this -MemberType Property ).Name
        
        if ( $this.Validate( $Value, $Properties ) ) {

            foreach ( $prop in $Properties ) {
                $this.$prop = $Value.$prop
            }

        } else {
            Throw ( "Description JSON does not contain at least one required property.`nRequired properties: {0}" -f ( $Properties -join ', ' ) )
        }

    }

    hidden [bool] Validate ( [pscustomobject]$Value, [string[]]$RequiredProperties ) {

        $Output = $true
        $ValueProperties = $Value.PSObject.Properties.Name

        foreach ( $prop in $RequiredProperties ) {
            $Output = $Output -and ( $prop -in $ValueProperties )
        }

        return $Output

    }

    hidden [string] Parse ( [string]$Value ) {

        $this.PrependingText = ( $Value -split $this.Prefix )[0]
        $this.TrailingText = ( $Value -split $this.Postfix )[-1]
        return [regex]::Match( $Value, "(?<=$($this.Prefix)).+(?=$($this.Postfix))" ).Value

    }

    hidden [string] ToString () {

        $Properties = ( Get-Member -InputObject $this -MemberType Property ).Name
        $JSON = $this | Select-Object -Property $Properties | ConvertTo-Json -Compress
        return ( $this.PrependingText + $this.Prefix + $JSON + $this.Postfix + $this.TrailingText )

    }

}