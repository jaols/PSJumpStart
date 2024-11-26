function Find-EnvironmentConfiguration {
<#
.SYNOPSIS
	Retrive a list of environment configuration data
.DESCRIPTION
	JSON files are read according to PSJumpstart standard. Then opened, converted to [PsCustomObject] and expression evaluation.
.PARAMETER EnvironmentTag
	Root tag name in JSON files to use as configuraion source. Default is "Environments"
.PARAMETER JsonFiles
    Json files to use for reading environment configurations. Use Get-SettingsFiles for Default

.Example

.Example 
#>
    [CmdletBinding(SupportsShouldProcess = $False)]    
    [OutputType("PSCustomObjec")]
    param(        
        [string]$EnvironmentTag="Environments",
        [string[]]$JsonFiles=(Get-SettingsFiles ".json")
    )

    foreach($settingsFile in $JsonFiles) {
        if (Test-Path $settingsFile) {        
            Write-Verbose "Reading [$EnvironmentTag] from file: [$settingsFile]"
            $EnvParameters = (Get-Content -Path $settingsFile -Encoding UTF8 | ConvertFrom-Json | Set-ValuesFromExpressions).$EnvironmentTag
            if ($EnvParameters) {
                ForEach($prop in $EnvParameters | Get-Member -MemberType NoteProperty) {
                    if (($prop.Name).IndexOf(':') -eq -1) {                                    
                        #Return each object. PSTypeName enables output Formatting
                        [PSCustomObject]@{
                            PSTypeName = "EnvironmentConfigInfo"
                            JsonFile=$settingsFile
                            EnvironmentTag=$EnvironmentTag
                            EnvironemntName=$prop.Name
                            Content=$EnvParameters.($prop.Name)
                        }
                    }
                }
            }
        } else {
            Write-Verbose "File not found: [$settingsFile]"
        }
    }
}
