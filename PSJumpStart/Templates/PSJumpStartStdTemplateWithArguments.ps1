 <#
.Synopsis
    Template 
.DESCRIPTION
    This template will load $PSDefaultParameterValues and the PSJumpStart module
    and has support for Write-Verbose, -WhatIf and whatnot.
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

#Load default arguemts for this script.
#Command prompt arguments will override file settings
function GetLocalDefaultsFromDfpFiles($CallerInvocation) {        
    #Load script default settings
    foreach($settingsFile in (Get-SettingsFiles $CallerInvocation ".dfp")) {
        Write-Verbose "File: [$settingsFile]"
        if (Test-Path $settingsFile) {        
            $settings = Get-Content $settingsFile
            #Enumerate settingsfile rows
            foreach($row in $settings) {
                #Remarked lines are not processed
                if (($row -match "=") -and ($row.Trim().SubString(0,1) -ne "#")) {
                    $key = $row.Split('=')[0]                            
                    $var = Get-Variable $key -ErrorAction SilentlyContinue
                    if ($var -and !($var.Value))
                    {
                        try {                
                            Write-Host "Var: $key" 
                            $var.Value = Invoke-Expression $row.SubString($key.Length+1)
                        } Catch {
                            $ex = $PSItem
                            $ex.ErrorDetails = "Err adding $key from $settingsFile. " + $PSItem.Exception.Message
                            throw $ex
                        }
                    }
                   #Write-Host "$($var.Value)"
                }
            }
        }
    }
}

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
if (-not (Get-Module PSJumpStart)) {
    Import-Module PSJumpStart -Force
}

#Get Local variable default values from external DFP-files
GetLocalDefaultsFromDfpFiles($MyInvocation)

#Get global deafult settings when calling modules
$PSDefaultParameterValues = Get-GlobalDefaultsFromDfpFiles($MyInvocation)

#endregion

Msg "Start Execution"

Write-Verbose "Script is in $scriptPath"

if ($pscmdlet.ShouldProcess("ActiveCode", "Run Code")) {
    #Put your commands/code here...
}

Msg "End Execution"