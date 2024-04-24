[CmdletBinding()]
Param()

#region local functions
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

function NestedMessage($firstMessage) {
    Msg $firstMessage    
    NestedNestedMessage $firstMessage

    #Return calc
    3+8
}

function NestedNestedMessage($secondLevelMessage) {    
    Msg $secondLevelMessage
}

#endregion

#Always re-load module
get-module PSJumpStart | Remove-Module;

#Load Module from script location 
#Import-Module "$(Split-Path -parent $MyInvocation.MyCommand.Definition)\..\PSJumpStart.psm1" -Force

#Standard import-module
Import-Module PSJumpStart -MinimumVersion 1.3.0 -Force

#Add script scope variable for json-file parsing!!
$Script:ScriptInvocation = $MyInvocation 

#Get Local variable default values from external DFP-files
Get-LocalDefaultVariables $MyInvocation 

#Get global deafult settings when calling modules
$PSDefaultParameterValues = Get-GlobalDefaultsFromJsonFiles($MyInvocation)

Msg "Start Execution"

#The verbose message will not be logged.
Write-Verbose "Olala"

#If -useFileLog is active the error will be put in that as well
Msg "Error has occurred. This messsage will be put in the eventlog. Regardless of other settings" "Error" -useEventLog

Msg "This message will be handled accoring to dfp settings."

$return=NestedMessage "This is a local nested function call"
$return

#Load external nested function
. "$(Split-Path -parent $MyInvocation.MyCommand.Definition)\NestedMsgCall.ps1"
FirstMsg "External function for message testing"


Msg "End Execution"