 <#
.Synopsis
    DemoCode
.DESCRIPTION
    DemoCode
.Notes
    Author: Jack    
#>
[CmdletBinding(SupportsShouldProcess = $False)]
param (
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
    foreach($settingsFile in (Get-SettingsFiles ".json")) {        
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

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
#if (-not (Get-Module PSJumpStart)) {
    Import-Module PSJumpStart -Force -MinimumVersion 2.0.0
#}

#Get Local variable default values from external JSON-files
Get-LocalDefaultVariables

#Get global deafult settings when calling modules
$PSDefaultParameterValues = Get-GlobalDefaultsFromJsonFiles $MyInvocation 

#endregion

$Error.Clear()
Write-Message "Start Execution"

Write-Message "List imported modules"
Write-Message "====================="
Get-ModuleHelp | Format-Table

Write-Message "List available Modules"
Write-Message "======================"
Get-ModuleHelp -ListAvailable | Format-Table

Write-Message "Search ALL available modules for commands containing 'address' and show where they are"
Write-Message "======================================================================================"
Get-ModuleHelp -ListAvailable -CommandName "*address*" | Select-Object Name,ModuleName,ModulePath | Format-Table

Write-Message "Get all help commands from installed modules"
Write-Message "============================================"
Get-ModuleHelp -CommandName "*Help*"

#Show any errors (but not variable not found OR the -SilentlyContinue GetAlias command)
if ($Error -ne $null) { foreach ($err in $Error) {
    if ($err -notmatch "Cannot find a variable with the name" -and 
        $err.FullyQualifiedErrorId -ne "ItemNotFoundException,Microsoft.PowerShell.Commands.GetAliasCommand") {
            Write-Message "`n$err `n       $($err.ScriptStackTrace) `n`n$($err.InvocationInfo.PositionMessage)`n`n" -Type Warning
    }
}}

Write-Message "End Execution"