function Get-GlobalDefaultsFromJsonFiles {
    <#
        .Synopsis
           Get global defaults to use with $PSDefaultParameterValues
        .DESCRIPTION
           Returns a DefaultParameterDictionary to load into $PSDefaultParameterValues
    
           The Defaults will be loaded according to priority:
            - User settings from a file named as UserLogonID in caller location or current location(?) is loaded as Prio 1 
            - LogonDomain (or machine name) file in Module location is Prio 2
            - Module name(s) settings is last in order.
                        
        .PARAMETER CallerInvocation
           The invocation object from the caller needed for bound parameters retreival
    
        .Notes
           For information about PSDefaultParameterValues check these articles:
    
           https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_parameters_default_values?view=powershell-6
           https://www.red-gate.com/simple-talk/sysadmin/powershell/powershell-time-saver-automatic-defaults/
    
    #>
    Param(
         [parameter(Position=0,mandatory=$true)]
         $CallerInvocation
    )    
        $result = New-Object System.Management.Automation.DefaultParameterDictionary
        
        foreach($settingsFile in (Get-SettingsFiles ".json")) {
            if (Test-Path "$settingsFile") {            
                Write-Verbose "Get-GlobalDefaultValues:[$settingsFile]"

                $DefaultParamters = Get-Content -Path $settingsFile -Encoding UTF8 | ConvertFrom-Json | Set-ValuesFromExpressions

                ForEach($property in $DefaultParamters.psobject.properties.name) {

                    if ($property.IndexOf(':') -ge 0) {                                                
                        $Variable = $property.Split(':')[1]

                        #We do not load default values if it exists among the BoundParameters
                        if (!$result.ContainsKey($property) -and -not $CallerInvocation.BoundParameters[$Variable].IsPresent) {
                            try {
                                $result.Add($property,$DefaultParamters.($property))
                            } catch {
                                $ex = $PSItem
                                $ex.ErrorDetails = "Err adding $property from $settingsFile. " + $PSItem.Exception.Message
                                throw $ex
                            }
                        }
                    }    
                }
            } else {
                Write-Verbose "Get-GlobalDefaultValues:[$settingsFile] missing"
            }
        }
        #Return Parameter Dictionary 
        [System.Management.Automation.DefaultParameterDictionary]$result
}
