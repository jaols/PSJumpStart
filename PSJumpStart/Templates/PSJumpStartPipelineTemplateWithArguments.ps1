 <#
.Synopsis
    Template 
.DESCRIPTION
    This template will load $PSDefaultParameterValues and the PSJumpStart module
    and has support for Write-Verbose, -WhatIf and whatnot.
.PARAMETER Name
   	First mandatory string argument. This CANNOT be set by JSON content BUT it may be fed by pipeline content.
.PARAMETER Action
   	Second optional string argument. This may be populated by JSON content and the function Get-LocalDefaultVariables
.PARAMETER Flag
	Switch parameter check with if ($flag:IsPresent) {}
.Notes
    Author: 
    Changes:

.Example
    Get-EventLog -List| Select @{n="Name";e={$_.Log}} | PSJumpStartStdTemplateWithArguments.ps1 -Action "Check"

    Pipe data into the script.
.Example
    PSJumpStartStdTemplateWithArguments.ps1 -Name "Olala" -Action "Check"

    Run process for single object


#>
[CmdletBinding(SupportsShouldProcess = $True)]
param (
    [Parameter(Mandatory = $true,
               ValueFromPipelineByPropertyName=$true)]
    [string]$Name,
    [string]$Action,
    [switch]$Flag 
)

Begin {
#Begin operations are run one time for pipeline processing

#region local functions 

#Load default arguemts for this script.
#Command prompt arguments will override file settings
function Get-LocalDefaultVariables {
    [CmdletBinding(SupportsShouldProcess = $False)]
    param(
        [parameter(Position=0,mandatory=$true)]
        $CallerInvocation,
        [switch]$defineNew,
        [switch]$overWriteExisting
    )
    foreach($settingsFile in (Get-SettingsFiles $CallerInvocation ".json")) {        
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
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
    if (-not (Get-Module PSJumpStart)) {
        Import-Module PSJumpStart -Force -MinimumVersion 1.2.0
    }
    
    #Get Local variable default values from external DFP-files
    Get-LocalDefaultVariables($MyInvocation)
    
    #Get global deafult settings when calling modules
    $PSDefaultParameterValues = Get-GlobalDefaultsFromJsonFiles $MyInvocation -Verbose:$VerbosePreference
    
    #endregion

    Msg "Start Execution"
}


Process {
#Process operations are run for each object in pipeline processing
    Write-Verbose "Script is in $scriptPath"

    if ($pscmdlet.ShouldProcess("ActiveCode", "Run Code")) {
        Msg "Processing value [$Name] try the [$Action]"
    }
}

End {
#End operations are run once in pipeline processing
    Msg "End Execution"
}