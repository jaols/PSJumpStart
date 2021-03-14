function Get-ModuleHelp {
<#
    .Synopsis
        Get help information for a specific module or a list of imported and available modules
    .DESCRIPTION
        
    .PARAMETER Name
        Mudule name.
    .PARAMETER CommandName
        Name of command in modules
    .NOTES
        Author: Jack Olsson
#>
[CmdletBinding()]
param(
    [string]$Name,
    [string]$CommandName,
    [switch]$Detail
)   

    If ([string]::IsNullOrEmpty($Name)) {
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
                "`nWorkflows"
                "----------"
                ($module.ExportedWorkflows).Values
            }

            If ($module.ExportedDscResources.Count -gt 0) {
                "`nDsc Resources"
                "--------------"
                $module.ExportedDscResources
            }

            If ($module.ExportedVariables.Count -gt 0) {
                "`nVariables"
                "----------"
                $module.ExportedVariables
            }
            If ($module.ExportedTypeFiles.Count -gt 0) {
                "`nType Files"
                "-----------"
                $module.ExportedTypeFiles
            }

            If ($module.ExportedFormatFiles.Count -gt 0) {
                "`nFormat files"
                "-------------"
                $module.ExportedFormatFiles
            }
            If ($module.ExportedCommands.Count -gt 0) {
                "`nCommands"
                "--------"
                ($module.ExportedCommands).Values |Select-Object Name,CommandType,Version
            }
            If ($module.ExportedAliases.Count -gt 0) {                        
                "`nAliases"
                "-------"
                $aliases = $module.ExportedAliases
                $aliases.Keys | ForEach-Object {
                    $aliases[$_].Name + " -> " + $aliases[$_].Definition
                }
            }
            

        }
        

    }

}
