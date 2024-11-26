function Get-SettingsFiles {
    <#
        .Synopsis
           Get a list of setting files
        .DESCRIPTION
           Using [System.Security.Principal.WindowsIdentity]::getCurrent() ths function returns a list of setting files with the following content:
    
            - File named as user LogonID in caller location or current location(?)
            - LogonDomain (or machine name) file at caller location
            - Caller settingsfile at caller location
            - LogonDoamin (or machine name) file at this PSM-mudules location
        
        .PARAMETER extension
           File name suffix to use.
    #>
    [CmdletBinding()]
    Param(
         [parameter(Position=0,mandatory=$true)]
         [string]$extension
    ) 
    
        #$globalLocation = $PSScriptRoot
        $globalLocation = Split-Path -parent (Get-Module PSJumpStart | Select-Object -ExpandProperty Path)

        Write-Verbose "Global location: $globalLocation"
        
        $callStack = Get-PSCallStack | Select-Object ScriptName
        for ($i = $callStack.Count-1; $i -gt 0; $i--) {                        
            if (![string]::IsNullOrEmpty($callStack[$i].ScriptName)) {                
                $callerLocation=Split-Path -parent $callStack[$i].ScriptName
                break                
            }
        }

        if ([string]::IsNullOrEmpty($callerLocation)) {
            $callerLocation = $PWD.Path
        }        
        Write-Verbose "Caller location: $callerLocation"
        
        [reflection.assembly]::LoadWithPartialName("System.Security.Principal.WindowsIdentity") |Out-Null
        $user = [System.Security.Principal.WindowsIdentity]::getCurrent()    
        $UserID = ($user.Name -split '\\')[1]
        $LogonContext = ($user.Name -split '\\')[0]
        
        Write-Verbose "UserId: $UserId"
        Write-Verbose "Context: $LogonContext"
        Write-Verbose "ComputerName: $($Env:COMPUTERNAME)"

        #Add local environment settingsfiles (user specific or domain/computer specific)
        #also script specific defaults (local vars??) 
        $settingFiles = @(        
            "$callerLocation\$UserID$extension"
            "$callerLocation\$($Env:COMPUTERNAME)$extension"
            "$callerLocation\$LogonContext$extension"
            ($callStack[$i].ScriptName -replace ".ps1","") + "$extension"
            "$globalLocation\$($Env:COMPUTERNAME)$extension"
            "$globalLocation\$LogonContext$extension"
        ) | Select-Object -Unique
    
        #Add module specific setting xml-files
        Get-Module | Select-Object -ExpandProperty Name | ForEach-Object {
            $settingFiles += "$globalLocation\$_$extension"
        }
        
        $settingFiles
    }
    