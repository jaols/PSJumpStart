 <#
.Synopsis
    Demo of environment json file usage
.DESCRIPTION
    This demo will read json-files according to PSJumpstart standard and present configuration accoring to named environment name
.PARAMETER Name
    Name of environment to use as configuration source
.Notes
    Author: Jack
    Changes:
#>
[CmdletBinding(SupportsShouldProcess = $True)]
param (
    [string]$Name
)

#region local functions 

#Load default arguemts for this script.
#Command prompt arguments will override file settings
function Get-LocalDefaultVariables {
    [CmdletBinding(SupportsShouldProcess = $False)]
    param(
        [switch]$defineNew,
        [switch]$overWriteExisting
    )
    foreach($settingsFile in (Get-SettingsFiles ".json")) {        
        if (Test-Path $settingsFile) {        
            Write-Verbose "Reading file: [$settingsFile]"
            $DefaultParamters = Get-Content -Path $settingsFile -Encoding UTF8 | ConvertFrom-Json
            ForEach($prop in $DefaultParamters | Get-Member -MemberType NoteProperty) {        
                
                if (($prop.Name).IndexOf(':') -eq -1) {
                    $key=$prop.Name
                    $var = Get-Variable $key -ErrorAction SilentlyContinue
                    $value = $DefaultParamters.($prop.Name)                    
                    if (!$var) {
                        if ($defineNew) {
                            Write-Verbose "New Var: $key" 
                            if ($value.GetType().Name -eq "String" -and $value.SubString(0,1) -eq '(') {
                                $var = New-Variable -Name  $key -Value (Invoke-Expression $Value) -Scope 1
                            } else {
                                $var = New-Variable -Name  $key -Value $value -Scope 1
                            }
                        }
                    } else {

                        #We only overwrite non-set values if not forced
                        if (!($var.Value) -or $overWriteExisting)
                        {
                            try {                
                                Write-Verbose "Var: $key" 
                                if ($value.GetType().Name -eq "String" -and $value.SubString(0,1) -eq '(') {
                                    $var.Value = Invoke-Expression $value
                                } else {
                                    $var.Value = $value
                                }
                            } Catch {
                                $ex = $PSItem
                                $ex.ErrorDetails = "Err adding $key from $settingsFile. " + $PSItem.Exception.Message
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

Import-Module PSJumpStart -Force -MinimumVersion 2.0.0


#Get Local variable default values from external JSON-files
#The defineNew will load ALL new variables found!
Get-LocalDefaultVariables -defineNew

#Get global deafult settings when calling modules
$PSDefaultParameterValues = Get-GlobalDefaultsFromJsonFiles $MyInvocation -Verbose:$VerbosePreference

#endregion

$Error.Clear()
Write-Message "Start Execution"

Write-Message "Use passive configuration retreival from calling 'Get-LocalDefaultVariables' with '-defineNew' option (usage not recommended)"
$cfg=$Environments.$Name
if (!$cfg.SQLserver) {
    $Environments | ConvertTo-Json
} else {    
    $cfg | ConvertTo-Json
}

Write-Message "Use active loading of configurations"

$cfg=$null
$cfg=Get-EnvironmentConfiguration $Name -Verbose:$VerbosePreference
if ($cfg.Count -eq 0) {
    #Find ALL available configurations in json settings files 
    Find-EnvironmentConfiguration | Format-Table    
} else {
    $cfg
}

Write-Message "Use active loading of configurations from a specific file"

$cfg=$null
$cfg=Get-EnvironmentConfiguration $Name -JsonFiles ($PSCommandPath -replace ".ps1",".json") -Verbose:$VerbosePreference
if ($cfg.Count -eq 0) {
    #Find available configurations in json settings files
    Find-EnvironmentConfiguration -JsonFiles ($PSCommandPath -replace ".ps1",".json") | Format-List
} else {
    $cfg
}

Write-Message "Let's play with Planning system settings"
$Planning.Future.Time

Msg "Retreive Planning time for [$Name]"
$cfg=$null
$cfg=Get-EnvironmentConfiguration $Name -EnvironmentTag "Planning" -JsonFiles ($PSCommandPath -replace ".ps1",".json") -Verbose:$VerbosePreference
if ($cfg.Count -eq 0) {
    #Find available configurations in json settings files
    Find-EnvironmentConfiguration -EnvironmentTag "Planning" -JsonFiles ($PSCommandPath -replace ".ps1",".json") | Format-Table
} else {
    $cfg
}



#Show any errors (but not variable not found)
if ($Error -ne $null) { foreach ($err in $Error) {if ($err -notmatch "Cannot find a variable with the name") {
    Write-Verbose "Err: - `n$err `n       $($err.ScriptStackTrace) `n`n$($err.InvocationInfo.PositionMessage)`n`n"
}}}


Write-Message "End Execution"