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
        
        .PARAMETER CallerInvocation
           The invocation object from the caller.
        .PARAMETER extension
           File name suffix to use.
    #>
    [CmdletBinding()]
    Param(
         [parameter(Position=0,mandatory=$true)]
         $CallerInvocation,
         [parameter(Position=1,mandatory=$true)]
         [string]$extension
    ) 
    
        $globalLocation =  $PSScriptRoot
        Write-Verbose "Global location: $globalLocation"

        $callerLocation = Split-Path -parent $CallerInvocation.MyCommand.Definition
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

        #Add local environment settingsfiles (user specific or domain/computer specific)
        #also script specific defaults (local vars??) 
        $settingFiles = @(        
            "$callerLocation\$UserID$extension"
            "$callerLocation\$LogonContext$extension"
            ($CallerInvocation.MyCommand.Definition -replace ".ps1","") + "$extension"
            "$globalLocation\$LogonContext$extension"        
        )
    
        #Add module specific setting xml-files
        Get-Module | Select-Object -ExpandProperty Name | ForEach-Object {
            $settingFiles += "$globalLocation\$_$extension"
        }
        
        $settingFiles
    }
    