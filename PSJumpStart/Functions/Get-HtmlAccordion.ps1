function Get-HtmlAccordion {
    [CmdletBinding()]
    param(                
        [Parameter(ValueFromPipeline=$true)]
        $InputData,        
        [string]$DataName,
        [switch]$Fragment,
        [int]$panelCount = 1
    )
    Begin {
        Add-Type -AssemblyName System.Web
    
        $result = New-Object Text.StringBuilder
    
        if (!$Fragment) {
            #Add stylesheet and script
            [void]$result.AppendLine("<!DOCTYPE html>")
            [void]$result.AppendLine("<html><head>")
            [void]$result.AppendLine("<link rel='stylesheet' href='https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css' integrity='sha384-1BmE4kWBq78iYhFldvKuhfTAU6auU8tT94WrHftjDbrCEXSU1oBoqyl2QvZ6jIW3' crossorigin='anonymous'>")        
            [void]$result.AppendLine("<script src='https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.min.js' integrity='sha384-QJHtvGhmr9XOIpI6YVutG+2QOK9T+ZnN4kzFN1RtK3zEFEIsxhlmWl5/YESvpZ13' crossorigin='anonymous'></script>")
            [void]$result.AppendLine("</head>")
            [void]$result.AppendLine("<body>")
            [void]$result.AppendLine("<div class='accordion accordion-flush'>")
        }
    }
    Process {
        #Convert hashtable to PSCustomObject (if detected)
        if ($InputData.Gettype().Name -eq "Hashtable") {
            $InputData = [pscustomobject]$InputData
        }
    
        foreach ($key in $InputData.psobject.properties.name) {
            [void]$result.AppendLine("<div class='accordion-item'>")        
            [void]$result.AppendLine("<h4 class='accordion-header' id=heading$DataName$panelCount>")
            if ($Fragment) {
                [void]$result.AppendLine("<button class='accordion-button collapsed' type='button' data-bs-toggle='collapse' data-bs-target='#collapse$DataName$panelCount' aria-expanded='false' aria-controls='collapse$DataName$panelCount'>")
            } else {
                [void]$result.AppendLine("<button class='accordion-button' type='button' data-bs-toggle='collapse' data-bs-target='#collapse$DataName$panelCount' aria-expanded='true' aria-controls='collapse$DataName$panelCount'>")
            }
            [void]$result.AppendLine([System.Web.HttpUtility]::HtmlEncode($key))
            [void]$result.AppendLine("</button>")   
            [void]$result.AppendLine("</h4>") #'panel-title'        
            if ($Fragment) {
                [void]$result.AppendLine("<div id='collapse$DataName$panelCount' class='accordion-collapse collapse' aria-labelledby='heading$DataName$panelCount'>")
            } else {
                [void]$result.AppendLine("<div id='collapse$DataName$panelCount' class='accordion-collapse collapse show' aria-labelledby='heading$DataName$panelCount'>")
            }
    
            $panelCount++
    
            [void]$result.AppendLine("<ul class='list-group'>")
            forEach ($panelContent in $inputData.$key) {
                [void]$result.AppendLine("<li class='list-group-item'>")
                switch ($panelContent.Gettype().Name) {
                    "PSCustomObject" {                    
                        [void]$result.AppendLine((Get-HtmlAccordion -inputData $panelContent -DataName $Key -panelCount $panelCount -Fragment))
                        $panelCount=$result.Length
                    }
                    "Hashtable" {                    
                        [void]$result.AppendLine((Get-HtmlAccordion -inputData $panelContent -DataName $Key -panelCount $panelCount -Fragment))
                        $panelCount=$result.Length
                    }
                    Default {                    
                        [void]$result.Append([System.Web.HttpUtility]::HtmlEncode($panelContent))
                    }
                }        
                [void]$result.AppendLine("</li>") # class='list-group-item'
            }
            [void]$result.AppendLine("</ul>") # class='list-group'
            [void]$result.AppendLine("</div>") #accordion-collapse collapse
            [void]$result.AppendLine("</div>") #accordion-item
        }
    }
    End {
    
        if (!$Fragment) {
            [void]$result.AppendLine("</div></body></html>")        
        }
    
        return $result.ToString();
    }
}
