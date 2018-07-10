 <#
.Synopsis
    Template 
.DESCRIPTION
    This template is stand alone and has argument parsing and support for -Whatif and whatnot.
.PARAMETER arg1
   	First mandatory string argument.
.PARAMETER arg2
   	Second optional string argument.
.PARAMETER flag
	Switch parameter check with if ($flag:IsPresent) {}
.Notes
    Author: 
    Changes:
#>
[CmdletBinding(SupportsShouldProcess = $True)]
param (
    [Parameter(Mandatory = $true,
               ValueFromPipelineByPropertyName=$true)]
    [string]$arg1,
    [string]$arg2,
    [switch]$flag
)

#region Init

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition

#endregion

Msg "Start Execution"

Write-Verbose "Script is in $scriptPath"

if ($pscmdlet.ShouldProcess("ActiveCode", "Run Code")) {
    #Put your commands/code here...
}

Msg "End Execution"