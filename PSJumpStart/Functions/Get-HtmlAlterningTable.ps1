function Get-HtmlAlternatingTable {
    <#
    .SYNOPSIS
        Get a one or two column alternating HTML table from input object. 
    .DESCRIPTION
        The generated HTML table is a fixed style table with object member names in left column and values in the right column.
    .PARAMETER Header
        Set a header text for the table
    .PARAMETER InputData
        Data to process. This can be a Hashtable, PSCustomObject, String, String[] or Object[]
    .NOTES
        This table can be used as part of (inserted into) a mail message.
    #>
    [CmdletBinding()]
    param(        
        [string]$Header,
        [Parameter(ValueFromPipeline=$true)]
        [Object]$InputData
    )

    Begin {

        Add-Type -AssemblyName System.Web
        $result = New-Object Text.StringBuilder
        [void]$result.Append("<table style='border-collapse:separate;width:100%'>")

        #Set the header 
        if (![string]::IsNullOrEmpty($Header)) {
            [void]$result.Append("<tr><td style='background-color: #5D7B9D;color: white;' rowspan='1' colspan='2'><b>")
            [void]$result.Append([System.Web.HttpUtility]::HtmlEncode($Header))
            [void]$result.Append("</b></td></tr>")
        }

        $i = 0
    }

    Process {    
        $lineStyle=("background-color: #ffffff;","background-color: #D0D3D4;")
    
        switch ($InputData.Gettype().Name) {
            "String"  { 
                [void]$result.Append("<tr>")
                [void]$result.Append("<td>" + [System.Web.HttpUtility]::HtmlEncode($InputData) + "</td>")
                [void]$result.Append("</tr>");
            }
            {$_ -eq "Hashtable" -or $_ -eq "OrderedDictionary" -or $_ -eq "Dictionary"}
            {  
                foreach ($Key in $InputData.Keys)
                {                
                    [void]$result.Append("<tr style='" + $lineStyle[($i++ % 2)] + "'\>")
                    [void]$result.Append("<td><b>" + [System.Web.HttpUtility]::HtmlEncode($Key) + ":</b></td>")
                    [void]$result.Append("<td>" + [System.Web.HttpUtility]::HtmlEncode($InputData[$Key]) + "</td>")
                    [void]$result.Append("</tr>");
                }      
                break  
            }
            "PSCustomObject"  {  
                foreach ($Key in $InputData.psobject.properties.name)
                {
                    [void]$result.Append("<tr style='" + $lineStyle[($i++ % 2)] + "'\>")
                    [void]$result.Append("<td><b>" + [System.Web.HttpUtility]::HtmlEncode($Key) + ":</b></td>")
                    [void]$result.Append("<td>" + [System.Web.HttpUtility]::HtmlEncode($InputData.$Key) + "</td>")
                    [void]$result.Append("</tr>");                    
                }
            }
            {$_ -eq "Object[]" -or $_ -eq "String[]"} {
                foreach ($value in $InputData)
                {
                    [void]$result.Append("<tr style='" + $lineStyle[($i++ % 2)] + "'\>")
                    [void]$result.Append("<td>" + [System.Web.HttpUtility]::HtmlEncode($value.ToString()) + "</td>")
                    [void]$result.Append("</tr>");
                }      
                break  
            }
            Default {
                [void]$result.Append("<tr>")
                [void]$result.Append("<td>UNSUPPORTED DATA TYPE [" + $InputData.Gettype().Name + "]</td>")
                [void]$result.Append("</tr>");
                break
            }
        }    
    }

    End {
        
        [void]$result.Append("</table>");
        return $result.ToString();
    }
}