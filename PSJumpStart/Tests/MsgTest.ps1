#Load standard arguments from file (even evaluate code)
#Run code from PSM-file?
#scriptfilename -> domain name/server name -> global settings
[CmdletBinding(SupportsShouldProcess = $True, DefaultParameterSetName='FileLog')]
Param(
     [parameter(Position=0,mandatory=$false)]
	 [string]$Message,
 	 [parameter(mandatory=$false)]     
	 [string]$Type = "INFORMATION",
     [parameter(ParameterSetName='EventLog')]
     [switch]$useEventLog,
  	 [parameter(ParameterSetName='EventLog',mandatory=$false)]
	 [string]$EventLogName = "Application",
  	 [parameter(ParameterSetName='EventLog',mandatory=$false)]
	 [int]$EventId = 4695,     
     [parameter(ParameterSetName='FileLog')]
     [switch]$useFileLog,
     [parameter(ParameterSetName='FileLog')]
     [string]$logPath
)

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

function ImportModuleFromAnyLocation($CallerInvocation,$ModuleName) {
    try {
        #Try loading module from std-PowerShell locations:
        # C:\Users\%userID%\Documents\WindowsPowerShell\Modules or something like that
        Import-Module $ModuleName -Force
    } catch {
        #OK then let's search for it
        Import-Module "$(Split-Path -parent $CallerInvocation.MyCommand.Definition)\PSJumpStart.psm1" -Force
    }
}
get-module PSJumpStart | Remove-Module;


#PATH: C:\Users\%userID%\Documents\WindowsPowerShell\Modules\PSJumpStart??
#Import-Module "PSJumpStart" -Force

#Load Module from script location 
Import-Module "$(Split-Path -parent $MyInvocation.MyCommand.Definition)\PSJumpStart.psm1" -Force

#Get Local variable default values from external DFP-files
GetLocalDefaultsFromDfpFiles($MyInvocation)

#Get global deafult settings when calling modules
$PSDefaultParameterValues = Get-GlobalDefaultsFromDfpFiles($MyInvocation)


Msg "Start Execution"

Write-Verbose "Olala"

$TheHash = @{}

AddToHash $TheHash "test" "First value to have."
AddToHash $TheHash "test" " Add this as well"

$TheHash


Msg "End Execution"