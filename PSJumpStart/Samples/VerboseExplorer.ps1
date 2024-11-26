[CmdletBinding(SupportsShouldProcess = $False)]
param (          
   [string]$MyMessage,
   [switch]$NoRecurse
)

#region Init
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
                        Write-Verbose "Var not found: $property"
                        if ($defineNew) {
                            Write-Verbose "New Var: $property"
                            $var = New-Variable -Name  $property -Value $value -Scope 1
                        }
                    } else {
                        Write-Verbose ("Found var: $property -> " + $value)
                        
                        #We only overwrite non-set values if not forced
                        if (!($var.Value) -or $overWriteExisting)
                        {
                            try {
                                Write-Verbose ("Set var: $property=" + $value)
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
#endregion

#get-module PSJumpStart | Remove-Module;

Import-Module PSJumpStart -MinimumVersion 2.0.0 -Force

#Get Local variable default values from external Json-files
Get-LocalDefaultVariables -defineNew

#Get global deafult settings when calling modules
$PSDefaultParameterValues = Get-GlobalDefaultsFromJsonFiles($MyInvocation)

#endregion

Write-Message "Start Execution"

#Show JSON file message OR argument
Write-Message "Is this? $MyMessage"

Write-Message "Show module help in verbose mode?"

Get-ModuleHelp -Name PSJumpStart

if (!$NoRecurse) {
    #Simple nested test
    . $MyInvocation.MyCommand -MyMessage "This message is passed as an argument" -NoRecurse
}

#Get-ModuleHelp -Available

Write-Message "End Execution"