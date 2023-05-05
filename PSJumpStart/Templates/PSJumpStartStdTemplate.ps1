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
if (-not (Get-Module PSJumpStart)) {
   Import-Module PSJumpStart -Force -MinimumVersion 1.2.0
}

Get-LocalDefaultVariables $MyInvocation -defineNew -overWriteExisting

#Get global deafult settings when calling modules
$PSDefaultParameterValues = Get-GlobalDefaultsFromJsonFiles $MyInvocation -Verbose:$VerbosePreference

#endregion

Msg "Start Execution"

Write-Verbose "Script is in $scriptPath"

if ($pscmdlet.ShouldProcess("ActiveCode", "Run Code")) {
    #Put your commands/code here...
}

#Show any errors (but not variable not found)
if ($Error -ne $null) { foreach ($err in $Error) {if ($err -notmatch "Cannot find a variable with the name") {
    Write-Verbose "Err: - `n$err `n       $($err.ScriptStackTrace) `n`n$($err.InvocationInfo.PositionMessage)`n`n"
}}}

Msg "End Execution"