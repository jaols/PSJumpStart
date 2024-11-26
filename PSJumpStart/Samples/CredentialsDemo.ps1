 <#
    .Synopsis
       Demo of credentials with Get-AccessCredential
    .DESCRIPTION
       Run this file two times. The first will ask for credentials and the second will use saved credentials
    .Notes
       Author date 
       Changes
#>
[CmdletBinding(SupportsShouldProcess = $True)]
param ()

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

#region Init
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
if (-not (Get-Module PSJumpStart)) {
   Import-Module PSJumpStart -Force -MinimumVersion 2.0.0
}

Get-LocalDefaultVariables -defineNew -overWriteExisting

#Get global deafult settings when calling modules
$PSDefaultParameterValues = Get-GlobalDefaultsFromJsonFiles $MyInvocation -Verbose:$VerbosePreference

#endregion

Write-Message "Start Execution"

#Cred files path is set in the json file for this test script
$Credentials=Get-AccessCredential -AccessName "Office365"

Write-Message("User name 4 access is: " + $Credentials.UserName)

Write-Message("Credential was/is saved here " + $PSDefaultParameterValues["Get-AccessCredential:CredFilesPath"] + ":")

Write-Message("Cred file(s) list:" + (Get-ChildItem -Path ($PSDefaultParameterValues["Get-AccessCredential:CredFilesPath"] + "\" + $env:ComputerName + "*.xml")))

#Always update (demo purpose)
$Credentials=Get-AccessCredential -AccessName "TheWorld" -renew

Write-Message "End Execution"