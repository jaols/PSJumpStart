#Load standard arguments from file (even evaluate code)
#Run code from PSM-file?
#scriptfilename -> domain name/server name -> global settings
[CmdletBinding(SupportsShouldProcess = $True)]
param (      
    $pstring,   
   [string]$one,   
   [int64]$isint,
   [string[]]$two,
   #[ValidateScript({ $_.GetType().FullName -eq 'System.Management.Automation.PSScriptCmdlet' })]
   $sessionParam
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

get-module PSJumpStart | Remove-Module;

#PATH: C:\Users\%userID%\Documents\WindowsPowerShell\Modules\PSJumpStart??
#Import-Module "PSJumpStart" -Force
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Import-Module PSJumpStart -Force

#Get Local variable default values from external DFP-files
GetLocalDefaultsFromDfpFiles($MyInvocation)

#Get global deafult settings when calling modules
$PSDefaultParameterValues = Get-GlobalDefaultsFromDfpFiles($MyInvocation)

#endregion

Msg "Start Execution"

Write-Verbose "Value for One is [$one]"

$TheHash = @{}
#Test nesting verbose messages
AddToHash $TheHash "test" "First value to have."
AddToHash $TheHash "test" " Add this as well"

#Simple nested test
verboseTest "This will NOT show if parameter -Verbose is used for the script. BUT it will if Verbose=$true is used in a dfp file."

Msg "End Execution"