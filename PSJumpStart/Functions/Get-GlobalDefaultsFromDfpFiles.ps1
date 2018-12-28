function Get-GlobalDefaultsFromDfpFiles {
    <#
        .Synopsis
           Get global defaults to use with $PSDefaultParameterValues
        .DESCRIPTION
           Returns a DefaultParameterDictionary to load into $PSDefaultParameterValues
    
           The Defaults will be loaded according to priority:
            - User settings from a file named as UserLogonID in caller location or current location(?) is loaded as Prio 1 
            - LogonDomain (or machine name) file in Module location is Prio 2
            - Module name(s) settings is last in order.
        
            Syntax for dfp-file entries is:
              argumentName="This is a default input parameter value for a script"                
              functionName:ParameterName=ValueOrCode 
    
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
        
        foreach($settingsFile in (Get-SettingsFiles $CallerInvocation ".dfp")) {                
            if (Test-Path "$settingsFile") {            
                Write-Verbose "Get-GlobalDefaultsFromDfpFiles:[$settingsFile]"
                $settings = Get-Content $settingsFile
                foreach($row in $settings) {                
                    #Row Syntax FunctionName:Variable=Value/Code
                    if (($row -match ":") -and ($row -match "=") -and ($row.Trim().SubString(0,1) -ne "#") -and $row.IndexOf('=') -gt $row.IndexOf(':')) {
                        $key = $row.Split('=')[0]               
                        $Variable = $key.Split(':')[1]
                        
                        #Prevent overriding arguments to caller
                        if (!$result.ContainsKey($key) -and -not $CallerInvocation.BoundParameters[$Variable].IsPresent) {
                            try {
                                #Add value from XML (OR result from PS-code execution)
                                $result.Add($key,(Invoke-Expression $row.SubString($key.Length+1)))
                                Write-Verbose "Get-GlobalDefaultsFromDfpFiles:$key = $($row.SubString($key.Length+1))" 
                            } catch {
                                $ex = $PSItem
                                $ex.ErrorDetails = "Err adding $key from $settingsFile. " + $PSItem.Exception.Message
                                throw $ex
                            }                    
                        } else {
                            Write-Verbose "Get-GlobalDefaultsFromDfpFiles:$key already set"
                        }
                    }
                }
            } else {
                Write-Verbose "Get-GlobalDefaultsFromDfpFiles:[$settingsFile] missing"
            }
        }
    
        #Return Parameter Dictionary 
        [System.Management.Automation.DefaultParameterDictionary]$result
    }
    