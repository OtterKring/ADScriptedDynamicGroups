<#
.SYNOPSIS
Get specific or all AD Groups marked as ScriptedDynamic

.DESCRIPTION
Get specific or all AD Groups marked as ScriptedDynamic

.PARAMETER InputObject
AD group object(s), their names or objectguids to identify the groups to return. If nothing is specified all ScriptedDynamic groups will be returend.

.EXAMPLE
Get-ADScriptedDynamicGroup

returns all AD groups containing the specific JSON information for ScripteDynamic groups in their description.

.EXAMPLE
'myDynGroup1','myDynGroup2' | Get-ADScripteDynamicGroup

returns the AD groups with the requested names. If they do not contain the necessary JSON information in their description, a warning message will be returned

.NOTES
2023-07-05 ... initial version by Maximilian Otter
#>
function Get-ADScriptedDynamicGroup {
    [CmdletBinding()]
    param (
        [Parameter( ValueFromPipeline )]
        [psobject[]]
        $InputObject
    )

    process {

        foreach ( $obj in $InputObject ) {

            $identifier = if ( $obj -is [string] ) {

                $obj

            } else {

                switch ( $obj.PSObject.Properties.Name ) {
                    { $_ -contains 'ObjectGUID' } { $obj.ObjectGUID; break }
                    { $_ -contains 'Name' } { $obj.Name; break }
                    Default {
                        Write-Warning ( "[{0}] cannot be resolved to fetch a group" -f $obj )
                    }
                }

            }

            try {
                Get-ADGroup $identifier -Properties Description |
                    Where-Object { process { ( [JSONDescription]$_.Description ).Type -eq 'ScriptedDynamic' } }
            } catch {
                Write-Warning ( "[{0}]`tError fetching group" -f $obj )
                $null
            }

        }


    }

    end {

        # if first cmd in (or without) pipeline and no parameters...
        if ( $MyInvocation.PipelinePosition -le 1 -and $PSBoundParameters.Count -eq 0 ) {

            $local:JD = [JSONDescription]::new()
            Get-ADGroup -Filter "Description -like '*$($JD.Prefix)*' -and Description -like '*$($JD.Postfix)*'" -Properties Description |
                Where-Object {
                    process {
                        $currentgroup = $_
                        try {
                            ( [JSONDescription]$_.Description ).Type -eq 'ScriptedDynamic'
                        } catch {
                            Write-Warning ( "[{0}]`tJSON Description invalid: {1}" -f $currentgroup.Name, $_.Exception.Message )
                        }
                    }
                }
                
        }

    }

}