 <#
    .Synopsis
       Template 
    .DESCRIPTION
       This basic template has support for Write-Verbose, -WhatIf and whatnot.
    .Notes
       Author:
       Changes:
#>
[CmdletBinding(SupportsShouldProcess = $True)]
param ()

#region Init
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
#endregion

Msg "Start Execution"

Write-Verbose "Script is in $scriptPath"

if ($pscmdlet.ShouldProcess("ActiveCode", "Run Code")) {
    #Put your commands/code here...
}

Msg "End Execution"