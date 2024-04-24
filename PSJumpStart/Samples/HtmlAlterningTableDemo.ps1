[CmdletBinding(SupportsShouldProcess = $True)]
Param(    
)

#region local functions


function LocalCssStyle {
   [CmdletBinding()]
    param(         
        [String]$CssStyle,
        [String]$ReplaceTag,
        [Parameter(ValueFromPipeline=$true)]
        $HtmlCode
    )

Begin {
    if ([string]::IsNullOrWhiteSpace($ReplaceTag)) {
        $ReplaceTag = "<head>"
    }
    if (Test-Path $CssStyle) {
        $CssStyle = Get-Content -Path $CssStyle
    }
            
    $Replace =  New-Object Text.StringBuilder
    [void]$Replace.AppendLine($ReplaceTag)
    [void]$Replace.AppendLine("<style>")
    [void]$Replace.AppendLine($CssStyle)
    [void]$Replace.AppendLine("</style>")
    
}


Process {    
    $result += $HtmlCode -replace $ReplaceTag,$Replace.ToString()            
}

End {
    return $result
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
       [parameter(Position=0,mandatory=$true)]
       $CallerInvocation,
       [switch]$defineNew,
       [switch]$overWriteExisting
   )
   foreach($settingsFile in (Get-SettingsFiles $CallerInvocation ".json")) {        
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

Import-Module PSJumpStart -Force -MinimumVersion 1.3.0
#Import-Module "$scriptPath\..\PSJumpStart" -Force


Get-LocalDefaultVariables $MyInvocation -defineNew -overWriteExisting

#Get global deafult settings when calling modules
$PSDefaultParameterValues = Get-GlobalDefaultsFromJsonFiles $MyInvocation -Verbose:$VerbosePreference

#endregion
Msg "Start Execution"

$n=0
$outFile = $env:TEMP + "\htmlTest"

$cssStyle = "<style>
    h3 {background-color: #5D7B9D;color: white;}
    th {background-color: #5D7B9D;color: white;}
    tr:nth-child(even) {background: #D0D3D4}
    tr:nth-child(odd) {background: #FFF}
    tr:hover {background-color: #a6a6a6;}
</style>"

$stdHeader = "<h3>Process list</h3>"

$htmlCode = get-process | ConvertTo-Html -Property Name,Path,Company -As List -Head $cssStyle -PreContent $stdHeader -Title "LIST OF PROCESSES"
$tmp = ($outFile + $n + ".html")
$htmlCode | Out-File -FilePath $tmp -Force

Msg "Use std components to create a HTML table (with all trimmings): $tmp"
Invoke-Expression $tmp

$n++

#THIS DOES NOT WORK AS WE GET A LIST OF [process] objects.
#Get-Process | Get-HtmlAlternatingTable -Header "Processes"

#We need to specify what we want (and we get a list of [PSCustomObject])
$htmlCode = Get-Process | Select-Object Name,Path,Company | Get-HtmlAlternatingTable -Header "Process list"
$tmp = ($outFile + $n + ".html")
$htmlCode | Out-File -FilePath $tmp -Force
Msg "Process list table PSJumpstart style: $tmp"
Invoke-Expression $tmp

$n++

#Array of string
$colours = @("Blue","White","Green")
$htmlCode = Get-HtmlAlternatingTable -InputData $colours -Header "List of colors"
$tmp = ($outFile + $n + ".html")
$htmlCode | Out-File -FilePath $tmp -Force

Msg "Simple array of strings table: $tmp"
Invoke-Expression $tmp

$n++

#Using a hashtable as input
$UserData = @{
    FirstName="Al"
    LastName="Mankind"
    Company="World Inc"
}
$htmlCode = Get-HtmlAlternatingTable -InputData $UserData -Header "User data"
$tmp = ($outFile + $n + ".html")
$htmlCode | Out-File -FilePath $tmp -Force

Msg "Hashtable sample: $tmp"
Invoke-Expression $tmp

Msg "End Execution"