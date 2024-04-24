function Compare-PSObjects {
<#
.SYNOPSIS
    Compares two objects property by property.
.DESCRIPTION
    The result will only contain missing and/or value differens from master object. Output object is populated with property names with two child properties - 'Ref' and 'Diff'.
    The 'Ref' property contains the Reference data and the 'Diff' property has the Difference data. If the Difference object is missing the property the value will be $null.

    Output object is null if all data in Reference object is present in the Difference objeect, but we do not care if the Difference object has more properties.
.PARAMETER Reference
    The source object, or master object if you will
.PARAMETER Difference
    The target object in the comparison
.EXAMPLE
    
    $a = New-Object psobject -Prop ([ordered] @{ One = 1; Two = 2; Three = 3})
    $b = New-Object psobject -Prop ([ordered] @{ One = 1; Two = 2})
  
    Compare-PSObjects $a $b

    Three
    -----
    @{Ref=3; Diff=}

.EXAMPLE
    This will create a JSON output according to missing items in the .\badcopy.json file

    Compare-PSObjects -Reference (Get-Content -raw ".\template.json" | ConvertFrom-Json) -Difference (Get-Content -raw ".\badcopy.json" | ConvertFrom-Json) | ConvertTo-Json -Depth 10
  
.OUTPUTS
    [PSCustomObject]

#>

    [CmdletBinding(SupportsShouldProcess = $False)]
    param (
        [Parameter(Mandatory)]
        [PSObject]$Reference,
        [Parameter(Mandatory)]
        [PSObject]$Difference
    )
    begin {
        #Write-Verbose -Message "Starting [$($MyInvocation.Mycommand)]"
    }

    process {
        #Hashtable
        $Result=[ordered]@{}
        

        #Custom object from Json-File
        foreach($property in $Reference.psobject.properties.name) {            
            Write-Verbose ("Property: " + $property)

            if ($Reference.$property.GetType().Name -match "Object$") {
                Write-Verbose ("Recurse: " + $Reference.$property + " [" + $Reference.$property.GetType().Name +"]")
                $diff=$null
                $diff=Compare-PSObjects -Reference $Reference.$property -Difference $Difference.$property -Verbose:$VerbosePreference
                if ($diff) {
                    $Result.Add($property,$diff)
                }
            } else {    
                if ($Reference.$property.count -eq 1) {            
                    if ($Reference.$property -ne $Difference.$property) {
                        $Result.Add("$property",[PSCustomObject]@{Ref=$Reference.$property;Diff=$Difference.$property})
                    }                    
                } else {
                    $PropertyDiffs=@()
                    for ($n=0;$n -lt $Reference.$property.count ; $n++) {                        
                        if ($Reference.$property[$n].GetType().Name -match "Object$") {
                            if (!$Difference.$property[$n]) {
                                $PropertyDiffs+=[PSCustomObject]@{Ref=$Reference.$property[$n];Diff=$null}
                            } else {
                                Write-Verbose ("Recurse: $property[$n] [" + $Reference.$property[$n].GetType().Name +"]")                            
                                $PropertyDiffs+=Compare-PSObjects -Reference $Reference.$property[$n] -Difference $Difference.$property[$n] -Verbose:$VerbosePreference
                            }
                        } else {                            
                            if (!$Difference.$property -or !$Difference.$property[$n]) {
                                $PropertyDiffs+=[PSCustomObject]@{Ref=$Reference.$property[$n];Diff=$null}
                            } else {
                                if ($Reference.$property[$n] -ne $Difference.$property[$n]) {
                                    $PropertyDiffs+=[PSCustomObject]@{Ref=$Reference.$property[$n];Diff=$Difference.$property[$n]}
                                }
                            }
                        }
                    }
                    if ($PropertyDiffs.Count -gt 0) {$Result.Add("$property",$PropertyDiffs)}
                }
            }
        }

        #Return PSCustomObject from Hashtable
        if ($Result.Count -gt 0) {return [pscustomobject]$Result}
    }

    end {
        #Write-Verbose -Message "Ending [$($MyInvocation.Mycommand)]"
    }

}