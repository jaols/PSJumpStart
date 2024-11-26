[CmdletBinding(SupportsShouldProcess = $True)]
Param(    
)

#region local functions

function tGet-HtmlAccordion {
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
                    [void]$result.AppendLine((tGet-HtmlAccordion -inputData $panelContent -DataName $Key -panelCount $panelCount -Fragment))
                    $panelCount=$result.Length
                }
                "Hashtable" {                    
                    [void]$result.AppendLine((tGet-HtmlAccordion -inputData $panelContent -DataName $Key -panelCount $panelCount -Fragment))
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

function Get-LocalDefaultVariables {
    <#
   .Synopsis
       Load default arguemts for this PS-file.
   .DESCRIPTION
       Get setting files according to load order and set variables.
       Command prompt arguments will override any file settings
   .PARAMETER CallerInvocation
       $MyInvocation of calling code session            
   .PARAMETER defineNew
       Add ALL variables found in setting files
   .PARAMETER overWriteExisting
       Turns the table for variable handling file content will override command line arguments                                
   #>
   [CmdletBinding(SupportsShouldProcess = $False)]
   param(
       [switch]$defineNew,
       [switch]$overWriteExisting
   )
   foreach($settingsFile in (Get-SettingsFiles  ".json")) {        
       if (Test-Path $settingsFile) {        
           Write-Verbose "$($MyInvocation.Mycommand) reading: [$settingsFile]"
           $DefaultParamters = Get-Content -Path $settingsFile -Encoding UTF8 | ConvertFrom-Json | Set-ValuesFromExpressions
           ForEach($property in $DefaultParamters.psobject.properties.name) {
               #Exclude PSDefaultParameterValues ("functionName:Variable":"Value")
               if (($property).IndexOf(':') -eq -1) {
                   $var = Get-Variable $property -ErrorAction SilentlyContinue
                   $value = $DefaultParamters.$property
                   if (!$var) {
                       if ($defineNew) {
                           Write-Verbose "New Var: $property"
                           $var = New-Variable -Name  $property -Value $value -Scope 1
                       }
                   } else {
                       #We only overwrite non-set values if not forced
                       if (!($var.Value) -or $overWriteExisting)
                       {
                           try {                
                               Write-Verbose "Var: $property" 
                               $var.Value = $value
                           } Catch {
                               $ex = $PSItem
                               $ex.ErrorDetails = "Err adding $property from $settingsFile. " + $PSItem.Exception.Message
                               throw $ex
                           }
                       }
                   }
               }
           }
       } else {
           Write-Verbose "File not found: [$settingsFile]"
       }
   }
}
#endregion

#region Init
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition

Import-Module PSJumpStart -Force -MinimumVersion 2.0.0
#Import-Module "$scriptPath\..\PSJumpStart" -Force


Get-LocalDefaultVariables -defineNew -overWriteExisting

#Get global deafult settings when calling modules
$PSDefaultParameterValues = Get-GlobalDefaultsFromJsonFiles $MyInvocation -Verbose:$VerbosePreference

#endregion
Write-Message "Start Execution"

$n=0
$outFile = $env:TEMP + "\htmlTest"

#Using PSCustomObject as input
$UserList = [PSCustomObject]@{
    Boss = @(
        "Al"
        "Mankind"
        "World Inc"
    )
    Contact = @(
        "Foo Bar"
        "foobar@world.inc"
    )
    CompanyInfo = @(
        "World inc"
        "Street name 2265"
        "+999 123456789"
        @{
            Workers=@(
                "Al Mankind"
                "Foo Bar"
                "James Bond"
                "Doctor Bombay"
            )
        }
    )
    Adresses = @{
        London=@{
            Street="Oxfordstreet 22"
            Zip="122 22"
        }
        "New York"=@{
            Street="2nd Avenue 9876"
            Zip="666 78"
        }
        "Tullinge"=@{
            Street="Storv�gen 22A"
            Zip="146 99"
        }
    }
}

$htmlCode = Get-HtmlAccordion -InputData $UserList
$tmp = ($outFile + $n + ".html")
$htmlCode | Out-File -FilePath $tmp -Force

Write-Message "PSCustomObject sample: $tmp"
Invoke-Expression $tmp

#Exit 

$n++

$htmlCode = Get-Process | Select-Object Name,Path,Company | Get-HtmlAccordion
$tmp = ($outFile + $n + ".html")
$htmlCode | Out-File -FilePath $tmp -Force

Write-Message "Get Process: $tmp"
Invoke-Expression $tmp


Write-Message "End Execution"