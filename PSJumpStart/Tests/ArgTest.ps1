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
                            Write-Verbose "Var: $key" 
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

Import-Module PSJumpStart -Force

#Get Local variable default values from external DFP-files
GetLocalDefaultsFromDfpFiles($MyInvocation)

#Get global deafult settings when calling modules
$PSDefaultParameterValues = Get-GlobalDefaultsFromDfpFiles($MyInvocation)

#endregion

Msg "Start Execution"

Write-Verbose "Value for One is $one"
$two

#Should still be [int64]
Write-Verbose "$($isint.GetType().FullName) ; $isint"

#$Root = [ADSI]"LDAP://RootDSE"
#$Root.rootDomainNamingContext

#Get-PSSessionConfiguration

Msg "End Execution"