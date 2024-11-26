 <#
    .Synopsis
       Template 
    .DESCRIPTION
       This template will load $PSDefaultParameterValues and the PSJumpStart module
       and has support for Write-Verbose, -WhatIf and whatnot.
    .Notes
       Author date 
       Changes
#>
[CmdletBinding(SupportsShouldProcess = $True)]
param ()

#region local functions
function Get-LocalDefaultVariables {
    <#
   .Synopsis
       Load default arguemts for this PS-file.
   .DESCRIPTION
       Get setting files according to load order and set variables.
       Command prompt arguments will override any file settings.
   .PARAMETER defineNew
       Add ALL variables found in all setting files. This will get full configuration from all json files
   .PARAMETER overWriteExisting
       Turns the table for variable handling making file content override command line arguments.
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
if (-not (Get-Module PSJumpStart)) {
   Import-Module PSJumpStart -Force -MinimumVersion 2.0.0
}

Get-LocalDefaultVariables -defineNew

#Get global deafult settings when calling modules
$PSDefaultParameterValues = Get-GlobalDefaultsFromJsonFiles $MyInvocation -Verbose:$VerbosePreference

#endregion

Write-Message "Start Execution"

Write-Verbose "Script is in $scriptPath"

if ($pscmdlet.ShouldProcess("ActiveCode", "Run Code")) {
    #Put your commands/code here...
}

#Show any errors (but not variable not found)
if ($Error -ne $null) { foreach ($err in $Error) {if ($err -notmatch "Cannot find a variable with the name") {
    Write-Verbose "Err: - `n$err `n       $($err.ScriptStackTrace) `n`n$($err.InvocationInfo.PositionMessage)`n`n"
}}}

Write-Message "End Execution"