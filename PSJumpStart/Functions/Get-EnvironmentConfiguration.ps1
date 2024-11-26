function Get-EnvironmentConfiguration {
<#
.SYNOPSIS
	Retrive configuration data for a named environment
.DESCRIPTION
	JSON files are read according to PSJumpstart priority standard. Then opened, converted to [PsCustomObject] and expression evaluation.    
.PARAMETER EnvironmentName
	Name of environment to get configuration data for
.PARAMETER EnvironmentTag
	Root tag name in JSON files to use as configuraion source. Default is "Environments"
.PARAMETER JsonFiles
    Json files to use for reading environment configurations. Use Get-SettingsFiles for Default

.Example
    $cftg=Get-EnvironmentConfiguration -EnvironmentName Dev

    Get configuration data for development under json tag "Environments"

.Example 
    $cftg=Get-EnvironmentConfiguration -EnvironmentName Prod -EnvironmentTag "SystemName"

    Get configuration data for production environment using "SystemName" tag

.Example 
    $cftg=Get-EnvironmentConfiguration -EnvironmentName Prod -JsonFiles MyJsonFile.json

    Get configuration data for production environment in single json file

.Example 
    $cftg=Get-EnvironmentConfiguration -EnvironmentName Prod -JsonFiles @("YourJsonFile.json","MyJsonFile.json")

    Get configuration data for production environment in two json files
#>
    [CmdletBinding(SupportsShouldProcess = $False)]
    [OutputType("OrderedDictionary")]
    param(                
        [string]$EnvironmentName,
        [string]$EnvironmentTag="Environments",
        [string[]]$JsonFiles=(Get-SettingsFiles ".json")
    )

    $result=[Ordered]@{}

    foreach($settingsFile in $JsonFiles) {
        if (Test-Path $settingsFile) {        
            Write-Verbose "Reading [$EnvironmentTag] from file: [$settingsFile]"
            $EnvParameters = (Get-Content -Path $settingsFile -Encoding UTF8 | ConvertFrom-Json | Set-ValuesFromExpressions).$EnvironmentTag
            if ($EnvParameters -and $EnvParameters.$EnvironmentName) {

                ForEach($prop in ($EnvParameters.$EnvironmentName | Get-Member -MemberType NoteProperty)) {
                    if (($prop.Name).IndexOf(':') -eq -1) {                                    
                        if (!$result.Contains($prop.Name)) {
                            Write-Verbose "Add value for: $($prop.Name)"
                            $value = $EnvParameters.$EnvironmentName.($prop.Name)
                            $result.Add($prop.Name,$Value)
                        }
                    }
                }
            }
        } else {
            Write-Verbose "File not found: [$settingsFile]"
        }
    }

    $result
}
