[CmdletBinding()]
param(
    $Arg1=(Get-Process -Name "PowerShell"),
    $StringValue,
    $Arg3
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
#endregion

Import-Module PSJumpStart -Force -MinimumVersion 2.0.0

#Retreive variables for this script (overwrite input arguments with -overWriteExisting).
Get-LocalDefaultVariables -Verbose -defineNew

#Get default paramters when calling functions (for example std-adserver)
$PSDefaultParameterValues = Get-GlobalDefaultsFromJsonFiles $MyInvocation 

#endregion

Write-Message "Start Execution"

$Arg1
Write-Message "Used static default value for Arg1 (not recommended)"

#Retreived from script json file
$PSpids
Write-Message "Used json file content as -defineNew option is in play"

Write-Message "Space added to prevent code evaluation in [$StringValue]"


Write-Message("The setting for RestApi Url is: [" + $RestApi.AccessUrl + "]")
Write-Message("The setting for RestApi Method is: [" + $RestApi.UseMethod + "]")

#Get-Variable | ConvertTo-Json | Msg

Write-Message "End Execution"
