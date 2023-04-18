function Get-ModuleHelp {
<#
    .Synopsis
        Get information on a specific module or a list of imported and available modules
    .DESCRIPTION
        The module information includes all available resources such as Workflows, Aliases and more.
    .PARAMETER Name
        Use module name filter option to limit help information to specific module(s)
    .PARAMETER CommandName
        Retreive comnmand information from all modules or from specifc module(s)
    .NOTES
        Author: Jack Olsson

    .EXAMPLE
        Get-ModuleHelp -Name PSJumpstart 

        List all exported resources for the 'PSJumpStart' module
    .EXAMPLE
        Get-ModuleHelp -CommandName clip

        List all loaded modules with resources containing the name 'clip'.
#>
[CmdletBinding()]
param(
    [string]$Name,
    [string]$CommandName,
    [switch]$Detail
)   

    If ([string]::IsNullOrEmpty($Name) -and [string]::IsNullOrEmpty($CommandName)) {
        
        "`nAvailable modules"
        "-----------------"
        #List installed Modules
        Get-InstalledModule | Select-Object Name, Version, Description

        #Get current active modules
        "`nImported modules"
        "----------------"
        Get-Module | Select-Object Name, Version, ModuleType        

    } else {
        Get-Module | Where-Object {$_.Name -like "*$name*"} | ForEach-Object {
            $module = $_
            "`n" + $module.Name
            "".PadRight(($module.Name).Length,'=')

            If ($module.ExportedWorkflows.Count -gt 0) {
                $result=$null
                $result=($module.ExportedWorkflows).Values | Where-Object {$_ -like "*$CommandName*"}

                if (![string]::IsNullOrEmpty($result)) {
                    "`nWorkflows"                
                    "----------"
                    $result
                }
                
            }

            If ($module.ExportedDscResources.Count -gt 0) {
                $result=$null
                $result=$module.ExportedDscResources | Where-Object {$_ -like "*$CommandName*"}

                if (![string]::IsNullOrEmpty($result)) {
                    "`nDsc Resources"
                    "--------------"
                    $result
                }
            }

            If ($module.ExportedVariables.Count -gt 0) {
                $result=$null
                $result=$module.ExportedVariables | Where-Object {$_ -like "*$CommandName*"}

                if (![string]::IsNullOrEmpty($result)) {
                    "`nVariables"
                    "----------"
                    $result
                }
                
            }
            If ($module.ExportedTypeFiles.Count -gt 0) {
                $result=$null
                $result=$module.ExportedTypeFiles | Where-Object {$_ -like "*$CommandName*"}

                if (![string]::IsNullOrEmpty($result)) {
                    "`nType Files"
                    "-----------"
                    $result
                }
                
            }

            If ($module.ExportedFormatFiles.Count -gt 0) {
                $result=$null
                $result=$module.ExportedFormatFiles | Where-Object {$_ -like "*$CommandName*"}

                if (![string]::IsNullOrEmpty($result)) {
                    "`nFormat files"
                    "-------------"
                    $result
                }
                
            }
            If ($module.ExportedCommands.Count -gt 0) {
                $result=$null
                $result=($module.ExportedCommands).Values | Where-Object {$_.Name -like "*$CommandName*"} | Select-Object Name,CommandType,Version

                if (![string]::IsNullOrEmpty($result)) {
                    "`nCommands"
                    "--------"
                    $result
                }
                
                
            }
            If ($module.ExportedAliases.Count -gt 0) {                        
                $result=$null
                $aliases = $module.ExportedAliases
                $aliases.Keys | Where-Object {$aliases[$_].Definition -like "*$CommandName*"} | ForEach-Object {
                    $result+=$aliases[$_].Name + " -> " + $aliases[$_].Definition + "`n"
                }
                
                if (![string]::IsNullOrEmpty($result)) {
                    "`nAliases"
                    "-------"
                    $result
                }
            }
        }
    }
}
