[CmdletBinding()]
Param()

#Load default arguemts for this script from the dfp setting files.
#Command prompt arguments will override any settings
function GetLocalDefaultsFromDfpFiles($CallerInvocation) {        
    #Load script default settings
    foreach($settingsFile in (Get-SettingsFiles $CallerInvocation ".dfp")) {
        #Write-Host "File: [$settingsFile]"
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

function NestedMessage($firstMessage) {
    Msg $firstMessage    
    NestedNestedMessage $firstMessage
}

function NestedNestedMessage($secondLevelMessage) {    
    Msg $secondLevelMessage
}
#Always re-load module
get-module PSJumpStart | Remove-Module;

#Load Module from script location 
Import-Module "$(Split-Path -parent $MyInvocation.MyCommand.Definition)\..\PSJumpStart.psm1" -Force

#Get Local variable default values from external DFP-files
GetLocalDefaultsFromDfpFiles($MyInvocation)

#Get global deafult settings when calling modules
$PSDefaultParameterValues = Get-GlobalDefaultsFromDfpFiles($MyInvocation)
#$Global:PSDefaultParameterValues = $PSDefaultParameterValues.Clone()


Msg "Start Execution"

#The verbose message will not be logged.
Write-Verbose "Olala"

#If -useFileLog is active the error will be put in that as well
Msg "Error has occurred. This messsage will be put in the eventlog. Regardless of other settings" "Error" -useEventLog

Msg "This message will be handled accoring to dfp settings."

NestedMessage "This is a local nested function call"

#Load external nested function
. "$(Split-Path -parent $MyInvocation.MyCommand.Definition)\NestedMsgCall.ps1"
nestedMsg "External function for message testing"


Msg "End Execution"