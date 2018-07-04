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

#region Init
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
if (-not (Get-Module PSJumpStart)) {
    Import-Module PSJumpStart -Force
}

#Get global deafult settings when calling modules
$PSDefaultParameterValues = Get-GlobalDefaultsFromDfpFiles($MyInvocation)

#endregion

Msg "Start Execution"

Write-Verbose "Script is in $scriptPath"

if ($pscmdlet.ShouldProcess("ActiveCode", "Run Code")) {
    #Put your commands/code here...
}

Msg "End Execution"