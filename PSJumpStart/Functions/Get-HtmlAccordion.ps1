function Get-HtmlAccordion {
    [CmdletBinding()]
    param(                
        [HashTable]$inputData,
        [switch]$Fragment,
        [int]$panelCount = 1
    )
    Add-Type -AssemblyName System.Web

    $result = New-Object Text.StringBuilder

    if (!$Fragment) {
        #Add stylesheet and script
        [void]$result.AppendLine("<!DOCTYPE html>")
        [void]$result.AppendLine("<html><head>")
        [void]$result.AppendLine("<link rel='stylesheet' href='https://cdn.jsdelivr.net/npm/bootstrap@4.4.1/dist/css/bootstrap.min.css' integrity='sha384-Vkoo8x4CGsO3+Hhxv8T/Q5PaXtkKtu6ug5TOeNV6gBiFeWPGFN9MuhOf23Q9Ifjh' crossorigin='anonymous'>")
        [void]$result.AppendLine("<script src='https://cdn.jsdelivr.net/npm/bootstrap@4.4.1/dist/js/bootstrap.min.js' integrity='sha384-wfSDF2E50Y2D1uUdj0O3uMBJnjuUD4Ih7YwaYd1iqfktj0Uod8GCExl3Og8ifwB6' crossorigin='anonymous'></script>")
        [void]$result.AppendLine("</head>")
        [void]$result.AppendLine("<body>")
        [void]$result.AppendLine("<div class='container'>")
    }

    
    foreach ($key in $inputData.Keys) {        
        [void]$result.AppendLine("<div class='panel-default'>")
        [void]$result.AppendLine("<div class='panel-heading' >")
        [void]$result.AppendLine("<h4 class='panel-title' id=heading$panelCount>")
        if ($noWrapping) {
            [void]$result.AppendLine("<button class='accordion-button collapsed' type='button' data-bs-toggle='collapse' data-bs-target='#collapse$panelCount' aria-expanded='false' aria-controls='collapse$panelCount'>")
        } else {
            [void]$result.AppendLine("<button class='accordion-button' type='button' data-bs-toggle='collapse' data-bs-target='#collapse$panelCount' aria-expanded='true' aria-controls='collapse$panelCount'>")
        }
        [void]$result.AppendLine([System.Web.HttpUtility]::HtmlEncode($key))
        [void]$result.AppendLine("</button>")   
        [void]$result.AppendLine("</h4>") #'panel-title'
        [void]$result.AppendLine("</div>") #'panel-heading'
        if ($noWrapping) {
            [void]$result.AppendLine("<div id='collapse$panelCount' class='panel-collapse collapse' aria-labelledby='heading$panelCount'>")
        } else {
            [void]$result.AppendLine("<div id='collapse$panelCount' class='panel-collapse collapse show' aria-labelledby='heading$panelCount'>")
        }

        $panelCount++

        [void]$result.AppendLine("<ul class='list-group'>")
        forEach ($panelContent in $inputData[$key]) {            
            [void]$result.AppendLine("<li class='list-group-item'>")
            switch ($panelContent.Gettype().Name) {
                "Hashtable" {
                    #This does not work at this time due to script error...
                    [void]$result.AppendLine((Get-HtmlAccordion -inputData $panelContent -panelCount $panelCount -noWrapping))
                    $panelCount++
                }
                Default {
                    
                    [void]$result.Append([System.Web.HttpUtility]::HtmlEncode($panelContent))
                }
            }        
            [void]$result.AppendLine("</li>") # class='list-group-item'
        }
        [void]$result.AppendLine("</ul>") # class='list-group'
        [void]$result.AppendLine("</div>") #panel-collapse collapse
        [void]$result.AppendLine("</div>") #panel panel-default
    }

    if (!$noWrapping) {
        [void]$result.AppendLine("</div></body></html>")        
    }

    return $result.ToString();
}