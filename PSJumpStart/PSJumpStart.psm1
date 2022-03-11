#Get PSJumpStart function files
$FunctionLib = @(Get-ChildItem -Path $PSScriptRoot\Functions\*.ps1 -ErrorAction SilentlyContinue)
#Get Local module lib function files
$LocalModuleLib = @(Get-ChildItem -Path $PSScriptRoot\LocalLib\*.ps1 -ErrorAction SilentlyContinue)
#Get Local lib function files (script folder OR current folder)
$LocalLibPath=$MyInvocation.PSScriptRoot
if ([string]::IsNullOrEmpty($LocalLibPath)) {    
    $LocalLibPath=$PWD.Path    
} 
$LocalLib = @(Get-ChildItem -Path $LocalLibPath\LocalLib\*.ps1 -ErrorAction SilentlyContinue)

#$functionNames = @()

#Import PSJumpstart functions
foreach($Import in $FunctionLib) {
    try {
        . $Import.FullName
        #$functionNames += ($Import.Name).Replace(".ps1","")
    }
    catch {
        Write-Error -Message "Failed to import function $($Import.FullName): $_"
    }
}
#Import local lib functions (override any PSJumpstart modules)
foreach($Import in $LocalModuleLib) {
    try {
        . $Import.FullName
        #$functionNames += ($Import.Name).Replace(".ps1","")
    }
    catch {
        Write-Error -Message "Failed to import function $($Import.FullName): $_"
    }
}

#Import local lib functions (override any functions)
foreach($Import in $LocalLib) {
    try {        
        . $Import.FullName
        #$functionNames += ($Import.Name).Replace(".ps1","")
    }
    catch {
        Write-Error -Message "Failed to import function $($Import.FullName): $_"
    }
}

#Export-ModuleMember -Function $functionNames
Export-ModuleMember -Function *

#region useless code?
function IsVerbose {
[CmdletBinding()]
param() 
   [bool](Write-Verbose ([String]::Empty) 4>&1)
}

function verboseTest {
[CmdletBinding()]
param($message) 
    Write-Verbose $message   
    Write-Verbose $ExecutionContext.SessionState.Path 
}

function GatherErrorTest
{
    Begin
    {
        $Error.Clear()
        $ErrorActionPreference = "SilentlyContinue"
    }

    Process
    {
        Get-AdUser -Identity "CrashThisCall"
        Get-NetAdapter -Name "TheNetWayToHell"
    }
    End
    {
        #Check ALL errors (this was a bad idea!!)
        foreach($err in $Error) {
            Msg "Line " + $err.InvocationInfo.ScriptLineNumber + ":" + $err.Exception "ERROR"
        }

    }
}

#endregion

#region Unused Code (for reading purposes only)

#Get global defaults to use with $PSDefaultParameterValues
#Returns a Hashtable to load into $PSDefaultParameterValues
#The Defaults will be loaded accoring to priority:
# User settings from userID-file in caller location or current location(?) is prio 1 
# LogonDomain (or machine name) XML-file in Module location is Prio 2
# Module name(s) settings is last in order.
# 
#function GetGlobalDefaultsFromXmlFiles($CallerInvocation) {
#    $result = New-Object System.Management.Automation.DefaultParameterDictionary
#        
#    foreach($settingsFile in (Get-SettingsFiles $CallerInvocation ".xml")) {
#        #Write-Host $settingsFile
#        if (Test-Path "$settingsFile") {
#            [xml]$settings = Get-Content $settingsFile
#            foreach($node in $settings.FirstChild.ChildNodes) {
#                $cmdLetName = $node.Name
#                foreach($setting in $settings.FirstChild.$cmdLetName.ChildNodes) {
#                    
#                    #We cannot have a wildcard in the XML-file so we use the point. (cruddy solution?)
#                    $key = ($cmdLetName).Replace('.','*') + ":" + $setting.Name
#                    if (!$result.ContainsKey($key)) {
#
#                        try {
#                            #Add value from XML (OR result from PS-code execution)
#                            $result.Add($key,(Invoke-Expression $setting.InnerText))
#                        } catch {
#                            $ex = $PSItem
#                            $ex.ErrorDetails = "Err adding $key from $settingsFile. " + $PSItem.Exception.Message
#                            throw $ex
#                        }                    
#                    }
#                }
#            }
#        }
#    }
#
#    #Return Parameter Dictionary 
#    [System.Management.Automation.DefaultParameterDictionary]$result
#}

#These will only return the modules path no matter what!
#function Get-CallerLocation {
#    Split-Path $script:MyInvocation.MyCommand.Path -Parent
#    Split-Path -Leaf $MyInvocation.PSCommandPath  
#}
#
#function InternalModuleTest {
#    Get-CallerLocation
#}
#

#endregion
