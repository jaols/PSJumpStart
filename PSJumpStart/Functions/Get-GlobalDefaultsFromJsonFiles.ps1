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
           The invocation object from the caller.
    
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
        
        foreach($settingsFile in (Get-SettingsFiles $CallerInvocation ".json")) {                
            if (Test-Path "$settingsFile") {            
                Write-Verbose "Get-GlobalDefaultValues:[$settingsFile]"

                $DefaultParamters = Get-Content -Path $settingsFile -Encoding UTF8 | ConvertFrom-Json

                ForEach($prop in $DefaultParamters | Get-Member -MemberType NoteProperty) {

                    if (($prop.Name).IndexOf(':') -ge 0) {                        
                        $key=$prop.Name
                        $Variable = $key.Split(':')[1]

                        if (!$result.ContainsKey($key) -and -not $CallerInvocation.BoundParameters[$Variable].IsPresent) {
                            try {
                                $value = $DefaultParamters.($prop.Name)
                                if ($value.GetType().Name -eq "String" -and $value.SubString(0,1) -eq '(') {
                                    $result.Add($key,(Invoke-Expression -Command $value))
                                } else {
                                    $result.Add($key,$value)
                                }
                            } catch {
                                $ex = $PSItem
                                $ex.ErrorDetails = "Err adding $key from $settingsFile. " + $PSItem.Exception.Message
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
