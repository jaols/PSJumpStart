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
	Switch parameter check with "if ($flag:IsPresent) {}" or just "if ($flag) {}"
.Notes
    Author: 
    Changes:

.Example
    Get-EventLog -List| Select @{n="Name";e={$_.Log}} | PSJumpStartLightPipelineTemplate.ps1 -Action "Check"

    Pipe data into the script.
.Example
    PSJumpStartLightPipelineTemplate.ps1 -Name "Olala" -Action "Check"

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
    $Error.Clear()
    
    #region local functions
    function Get-LocalDefaultVariables {
        <#
       .Synopsis
           Load default arguemts for this PS-file.
       .DESCRIPTION
           Get setting files according to load order and set variables.
           Command prompt arguments will override any file settings.
       .PARAMETER defineNew
           Add ALL variables found in all setting files. This will get full configuration from all json files
       .PARAMETER overWriteExisting
           Turns the table for variable handling making file content override command line arguments.
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
    
    #Load functions from Functions folder      
    foreach($Import in @(Get-ChildItem -Path "$scriptPath\Functions\*.ps1" -ErrorAction SilentlyContinue)) {
        try {
            Write-Verbose "Load $($Import.FullName)"
            . $Import.FullName
        }
        catch {
            Write-Error -Message "Failed to import function $($Import.FullName): $_"
        }
    }
    #Load DLL-files from Functions folder      
    #foreach($Import in @(Get-ChildItem -Path "$scriptPath\Functions\*.dll" -ErrorAction SilentlyContinue)) {
    #    Write-Verbose "Add-Type $($Import.FullName)"
    #    Add-Type -Path $Import.FullName -Verbose:$VerbosePreference
    #}
    
    #Get Local variable default values from external DFP-files
    Get-LocalDefaultVariables
    
    #Get global deafult settings when calling modules
    $PSDefaultParameterValues = Get-GlobalDefaultsFromJsonFiles $MyInvocation -Verbose:$VerbosePreference
    
    #endregion
    
    Write-Message "Start Execution"
}
Process {
    #Process operations are run for each object in pipeline processing
    $PSDefaultParameterValues

    if ($pscmdlet.ShouldProcess("ActiveCode", "Run Code")) {
        Write-Message "Processing value [$Name] try action [$Action]"
    }
}
End {
    #End operations are run once in pipeline processing
    #Show any errors (but not variable not found)
    if ($Error -ne $null) { foreach ($err in $Error) {if ($err -notmatch "Cannot find a variable with the name") {
        Write-Verbose "Err: - `n$err `n       $($err.ScriptStackTrace) `n`n$($err.InvocationInfo.PositionMessage)`n`n"
    }}}

    Write-Message "End Execution"
}