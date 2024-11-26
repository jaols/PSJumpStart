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
        [switch]$defineNew,
        [switch]$overWriteExisting
    )
    foreach($settingsFile in (Get-SettingsFiles  ".json")) {        
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

Import-Module PSJumpStart -Force

#Get Local variable default values from external JSON-files
Get-LocalDefaultVariables -Verbose -defineNew

$PSDefaultParameterValues = Get-GlobalDefaultsFromJsonFiles $MyInvocation -Verbose

#endregion

Write-Message "Start Execution"

#Json file will have default values for theese arguments
Write-Verbose "Value for One is $one"
Write-Message("Valuew for Two: " + $two)

#SessionParam default value is part of the json file.
if ($sessionParam) {
    Write-Message("Notepad PID(s): " + $sessionParam.Id)
} else {
    Write-Message "No notepad is running" -Type Warning
}

#Should still be [int64]
Write-Verbose "$($isint.GetType().FullName) ; $isint"


Write-Message "End Execution"