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
    [CmdletBinding(SupportsShouldProcess = $False)]
    param(
        [parameter(Position=0,mandatory=$true)]
        $CallerInvocation,
        [switch]$defineNew,
        [switch]$overWriteExisting
    )
    foreach($settingsFile in (Get-SettingsFiles $CallerInvocation ".json")) {        
        if (Test-Path $settingsFile) {        
            Write-Verbose "Reading file: [$settingsFile]"
            $DefaultParamters = Get-Content -Path $settingsFile -Encoding UTF8 | ConvertFrom-Json
            ForEach($prop in $DefaultParamters | Get-Member -MemberType NoteProperty) {        
                
                if (($prop.Name).IndexOf(':') -eq -1) {
                    $key=$prop.Name
                    $var = Get-Variable $key -ErrorAction SilentlyContinue
                    $value = $DefaultParamters.($prop.Name)                    
                    if (!$var) {
                        if ($defineNew) {
                            Write-Verbose "New Var: $key" 
                            if ($value.GetType().Name -eq "String" -and $value.SubString(0,1) -eq '(') {
                                $var = New-Variable -Name  $key -Value (Invoke-Expression $Value) -Scope 1
                            } else {
                                $var = New-Variable -Name  $key -Value $value -Scope 1
                            }
                        }
                    } else {
 
                        #We only overwrite non-set values if not forced
                        if (!($var.Value) -or $overWriteExisting)
                        {
                            try {                
                                Write-Verbose "Var: $key" 
                                if ($value.GetType().Name -eq "String" -and $value.SubString(0,1) -eq '(') {
                                    $var.Value = Invoke-Expression $value
                                } else {
                                    $var.Value = $value
                                }
                            } Catch {
                                $ex = $PSItem
                                $ex.ErrorDetails = "Err adding $key from $settingsFile. " + $PSItem.Exception.Message
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

#Import-Module PSJumpStart -Force -MinimumVersion 1.2.1
Import-Module "$scriptPath\..\PSJumpStart" -Force


Get-LocalDefaultVariables $MyInvocation -defineNew -overWriteExisting

#Get global deafult settings when calling modules
$PSDefaultParameterValues = Get-GlobalDefaultsFromJsonFiles $MyInvocation -Verbose:$VerbosePreference

#endregion
Msg "Start Execution"

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
            Street="Storvägen 22A"
            Zip="146 99"
        }
    }
}

$htmlCode = Get-HtmlAccordion -InputData $UserList
$tmp = ($outFile + $n + ".html")
$htmlCode | Out-File -FilePath $tmp -Force

Msg "PSCustomObject sample: $tmp"
Invoke-Expression $tmp

#Exit 

$n++

$htmlCode = Get-Process | Select-Object Name,Path,Company | Get-HtmlAccordion
$tmp = ($outFile + $n + ".html")
$htmlCode | Out-File -FilePath $tmp -Force

Msg "Get Process: $tmp"
Invoke-Expression $tmp


Msg "End Execution"