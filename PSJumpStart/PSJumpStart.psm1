#region Under-Construction and test code

function verboseTest {
[CmdletBinding()]
param($message) 
    Write-Verbose $message   
    Write-Verbose $ExecutionContext.SessionState.Path 
}

function GatherErrorTest
{
    Begin
    {
        $Error.Clear()
        $ErrorActionPreference = "SilentlyContinue"
    }

    Process
    {
        Get-AdUser -Identity "CrashThisCall"
        Get-NetAdapter -Name "TheNetWayToHell"
    }
    End
    {
        #Check ALL errors (this was a bad idea!!)
        foreach($err in $Error) {
            Msg "Line " + $err.InvocationInfo.ScriptLineNumber + ":" + $err.Exception "ERROR"
        }

    }
}
function ExportDataTableToFile {
<#
.SYNOPSIS
    Dump a datatable to CSV-file OR XML-file
.DESCRIPTION
    Not much to add. It's fairly simple.
.PARAMETER CSVseparator
   	Character to use for CSV separation.
.PARAMETER CSVnoheader
	Do not export header (column names) to CSV.
.PARAMETER Header
	Use custom header (NOT column names) in CSV.
.PARAMETER Encoding
    Specifies the type of character encoding used in the file. Valid values are "Unicode", "UTF7", "UTF8", "UTF32","ASCII", "BigEndianUnicode", "Default", and "OEM".
.PARAMETER FileName
	Name of target file fo export.
.PARAMETER Xml
	Export to XML instead of CSV.
.NOTES
    Author: Jack Olsson
    Date:   2016-04-21
}
#>
param (
   [Parameter(Mandatory=$true,
              ValueFromPipeline=$true,
              ValueFromPipelineByPropertyName=$true)]
   [System.Data.Datatable]$DataTable,
   [Parameter(Mandatory=$true,              
              ValueFromPipelineByPropertyName=$true)]
   [string]$FileName,   
   [string]$CSVseparator,
   [switch]$CSVnoheader,
   [string]$Header,
   [string]$Encoding,
   [switch]$xml
   
)

Begin {
}
Process {
   Write-Verbose $DataTable.TableName
    if ($xml.IsPresent) {
	    ($DataTable | ConvertTo-XML -NoTypeInformation).Save($FileName)	
    } else {
	    if ($CSVnoheader.IsPresent) {
    		($DataTable | ConvertTo-Csv -Delimiter $CSVseparator -NoTypeInformation) -replace "`"", "" |  Select -Skip 1 | `
	    		Out-File -Encoding $Encoding -Force $FileName
	    } elseif (-not [string]::IsNullOrEmpty($Header)) {
            $Header | Out-File -Encoding $Encoding -Force $FileName
	    	($DataTable | ConvertTo-Csv -Delimiter $CSVseparator -NoTypeInformation) -replace "`"", "" |  Select -Skip 1 | `
		    	Out-File -Encoding $Encoding -Append $FileName 
 
        } else {
		    ($DataTable | ConvertTo-Csv -Delimiter $CSVseparator -NoTypeInformation) -replace "`"", "" | `
			    Out-File -Encoding $Encoding -Force $FileName
	    }
    }
}

End {
}
}
#endregion

#region "Production" functions
function Msg {
<#
    .Synopsis
       Main output function.
    .DESCRIPTION
       Writes messages to std-out OR host.
    .PARAMETER Message
       String to show and/or log to file or eventlog.
    .PARAMETER Type
       Message type, primarilly used for eventlog writing.
    .PARAMETER useEventLog
       Write message to windows EventLog (NOTE:This needs to be done as Administrator for first run)
    .PARAMETER EventLogName 
        The name of eventlog to write to
    .PARAMETER EventId
        Event ID number for EventLog 
    .PARAMETER useFileLog
        Write message to Log file (if omitted the message will be sent to std-out)
    .PARAMETER logFile
        Name of file to write message to.
    .PARAMETER logFilePath
        Target folder for log file. If omitted the script path is used.

    .EXAMPLE
       Msg "The secret is OUT"

       Writes "The secret is OUT" to std-out as "INFORMATION" message
    .EXAMPLE
       Msg "This was NO good" "ERROR"

       Writes the message to std-error
    .EXAMPLE
       Msg "This was NO good" "ERROR" -useEventLog

       Writes message to console (Write-Host) and to the windows Eventlog.
    .EXAMPLE
       Msg "Write this to file" -useFileLog

       Writes message to console (Write-Host) and to the standard log file name.
    #>
    [CmdletBinding(SupportsShouldProcess = $True, DefaultParameterSetName='FileLog')]
    Param(
     [parameter(Position=0,mandatory=$true)]
	 $Message,
 	 [parameter(Position=1,mandatory=$false)]
	 [string]$Type = "INFORMATION",
     [parameter(ParameterSetName='EventLog')]
     [switch]$useEventLog,
  	 [parameter(ParameterSetName='EventLog',mandatory=$false)]
	 [string]$EventLogName = "Application",
  	 [parameter(ParameterSetName='EventLog',mandatory=$false)]
	 [int]$EventId = 4695,     
     [parameter(ParameterSetName='FileLog')]
     [switch]$useFileLog,
     [parameter(ParameterSetName='FileLog')]
     [string]$logFile,
     [parameter(ParameterSetName='FileLog')]
     [string]$logFilePath

    )
    
    $scriptName = Split-Path -Leaf $MyInvocation.PSCommandPath  
	$logstring = (Get-Date).ToString() + ";" + $Message
    
    if ($useEventLog.IsPresent) {
        #We will get an error if not running as administrator
        try {
            if (![system.diagnostics.eventlog]::SourceExists($scriptName)) {
                [system.diagnostics.EventLog]::CreateEventSource($scriptName, $EventLogName)
            }
            Write-EventLog -LogName $EventLogName -Source $scriptName -EntryType $Type -Message $Message -EventId $EventId -Category 0
        } catch {
            Write-Error "ERROR;Run as ADMINISTRATOR;$($PSItem.Exception.Message)"
        }
        Write-Host "$Type;$logstring"            
    } else {
        if ($useFileLog.IsPresent) {
            #Write to console
            Write-Host "$Type;$logstring"
            if ([string]::IsNullOrEmpty($logFilePath) -or (!$logFile.Contains("\"))) {
                $logFilePath = $MyInvocation.PSCommandPath | Split-Path -Parent
            }

            if ([string]::IsNullOrEmpty($logFile)) {
                $logfile =  $logFilePath + ($MyInvocation.PSCommandPath | Split-Path -Leaf) + "." + (Get-Date -Format 'yyyy-MM') + ".log"
            }

            #Write to log file
            $stream = [System.IO.File]::AppendText($logFile)
	        $stream.WriteLine($logstring)
	        $stream.close()

        } else {
            if ($Type -match "Err") {
                Write-Error "$Type;$logstring"
            } else {
		        Write-Output "$Type;$logstring"
            }
        }    
    }
}

# https://blogs.technet.microsoft.com/heyscriptingguy/2014/04/26/weekend-scripter-access-powershell-preference-variables/
# https://gallery.technet.microsoft.com/scriptcenter/Inherit-Preference-82343b9d
#
function Get-CallerPreference
{
    <#
    .Synopsis
       Fetches "Preference" variable values from the caller's scope.
    .DESCRIPTION
       Script module functions do not automatically inherit their caller's variables, but they can be
       obtained through the $PSCmdlet variable in Advanced Functions.  This function is a helper function
       for any script module Advanced Function; by passing in the values of $ExecutionContext.SessionState
       and $PSCmdlet, Get-CallerPreference will set the caller's preference variables locally.
    .PARAMETER Cmdlet
       The $PSCmdlet object from a script module Advanced Function.
    .PARAMETER SessionState
       The $ExecutionContext.SessionState object from a script module Advanced Function.  This is how the
       Get-CallerPreference function sets variables in its callers' scope, even if that caller is in a different
       script module.
    .PARAMETER Name
       Optional array of parameter names to retrieve from the caller's scope.  Default is to retrieve all
       Preference variables as defined in the about_Preference_Variables help file (as of PowerShell 4.0)
       This parameter may also specify names of variables that are not in the about_Preference_Variables
       help file, and the function will retrieve and set those as well.
    .EXAMPLE
       Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

       Imports the default PowerShell preference variables from the caller into the local scope.
    .EXAMPLE
       Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -Name 'ErrorActionPreference','SomeOtherVariable'

       Imports only the ErrorActionPreference and SomeOtherVariable variables into the local scope.
    .EXAMPLE
       'ErrorActionPreference','SomeOtherVariable' | Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

       Same as Example 2, but sends variable names to the Name parameter via pipeline input.
    .INPUTS
       String
    .OUTPUTS
       None.  This function does not produce pipeline output.       
    .LINK
       about_Preference_Variables
    .NOTES
        
        https://gallery.technet.microsoft.com/scriptcenter/Inherit-Preference-82343b9d      
    #>

    [CmdletBinding(DefaultParameterSetName = 'AllVariables')]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ $_.GetType().FullName -eq 'System.Management.Automation.PSScriptCmdlet' })]
        $Cmdlet,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.SessionState]
        $SessionState,

        [Parameter(ParameterSetName = 'Filtered', ValueFromPipeline = $true)]
        [string[]]
        $Name
    )

    begin
    {
        $filterHash = @{}
    }
    
    process
    {
        if ($null -ne $Name)
        {
            foreach ($string in $Name)
            {
                $filterHash[$string] = $true
            }
        }
    }

    end
    {
        # List of preference variables taken from the about_Preference_Variables help file in PowerShell version 4.0

        $vars = @{
            'ErrorView' = $null
            'FormatEnumerationLimit' = $null
            'LogCommandHealthEvent' = $null
            'LogCommandLifecycleEvent' = $null
            'LogEngineHealthEvent' = $null
            'LogEngineLifecycleEvent' = $null
            'LogProviderHealthEvent' = $null
            'LogProviderLifecycleEvent' = $null
            'MaximumAliasCount' = $null
            'MaximumDriveCount' = $null
            'MaximumErrorCount' = $null
            'MaximumFunctionCount' = $null
            'MaximumHistoryCount' = $null
            'MaximumVariableCount' = $null
            'OFS' = $null
            'OutputEncoding' = $null
            'ProgressPreference' = $null
            'PSDefaultParameterValues' = $null
            'PSEmailServer' = $null
            'PSModuleAutoLoadingPreference' = $null
            'PSSessionApplicationName' = $null
            'PSSessionConfigurationName' = $null
            'PSSessionOption' = $null

            'ErrorActionPreference' = 'ErrorAction'
            'DebugPreference' = 'Debug'
            'ConfirmPreference' = 'Confirm'
            'WhatIfPreference' = 'WhatIf'
            'VerbosePreference' = 'Verbose'
            'WarningPreference' = 'WarningAction'
        }


        foreach ($entry in $vars.GetEnumerator())
        {
            if (([string]::IsNullOrEmpty($entry.Value) -or -not $Cmdlet.MyInvocation.BoundParameters.ContainsKey($entry.Value)) -and
                ($PSCmdlet.ParameterSetName -eq 'AllVariables' -or $filterHash.ContainsKey($entry.Name)))
            {
                $variable = $Cmdlet.SessionState.PSVariable.Get($entry.Key)
                
                if ($null -ne $variable)
                {
                    if ($SessionState -eq $ExecutionContext.SessionState)
                    {
                        Set-Variable -Scope 1 -Name $variable.Name -Value $variable.Value -Force -Confirm:$false -WhatIf:$false
                    }
                    else
                    {
                        $SessionState.PSVariable.Set($variable.Name, $variable.Value)
                    }
                }
            }
        }

        if ($PSCmdlet.ParameterSetName -eq 'Filtered')
        {
            foreach ($varName in $filterHash.Keys)
            {
                if (-not $vars.ContainsKey($varName))
                {
                    $variable = $Cmdlet.SessionState.PSVariable.Get($varName)
                
                    if ($null -ne $variable)
                    {
                        if ($SessionState -eq $ExecutionContext.SessionState)
                        {
                            Set-Variable -Scope 1 -Name $variable.Name -Value $variable.Value -Force -Confirm:$false -WhatIf:$false
                        }
                        else
                        {
                            $SessionState.PSVariable.Set($variable.Name, $variable.Value)
                        }
                    }
                }
            }
        }

    } # end

} # function Get-CallerPreference


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
Param(
     [parameter(Position=0,mandatory=$true)]
	 $CallerInvocation,
     [parameter(Position=1,mandatory=$true)]
     [string]$extension
) 

    $globalLocation =  $PSScriptRoot        
    $callerLocation = Split-Path -parent $CallerInvocation.MyCommand.Definition

    [reflection.assembly]::LoadWithPartialName("System.Security.Principal.WindowsIdentity") |Out-Null
    $user = [System.Security.Principal.WindowsIdentity]::getCurrent()    
    $UserID = ($user.Name -split '\\')[1]
    $LogonContext = ($user.Name -split '\\')[0]
    
    #Add local environment settingsfiles (user specific or domain/computer specific)
    #also script specific defaults (local vars??) 
    $settingFiles = @(        
        "$callerLocation\$UserID$extension"
        "$callerLocation\$LogonContext$extension"
        ($CallerInvocation.MyCommand.Definition -replace ".ps1","") + "$extension"
        "$globalLocation\$LogonContext$extension"        
    )

    #Add module specific setting xml-files
    Get-Module | Select -ExpandProperty Name | % {
        $settingFiles += "$globalLocation\$_$extension"
    }
    
    $settingFiles
}

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
            $settings = Get-Content $settingsFile
            foreach($row in $settings) {
                if (($row -match ":") -and ($row -match "=") -and ($row.Trim().SubString(0,1) -ne "#")) {                    
                    $key = $row.Split('=')[0]                    
                    
                    if (!$result.ContainsKey($key)) {
                        try {
                            #Add value from XML (OR result from PS-code execution)
                            $result.Add($key,(Invoke-Expression $row.SubString($key.Length+1)))
                        } catch {
                            $ex = $PSItem
                            $ex.ErrorDetails = "Err adding $key from $settingsFile. " + $PSItem.Exception.Message
                            throw $ex
                        }                    
                    }
                }
            }
        }
    }

    #Return Parameter Dictionary 
    [System.Management.Automation.DefaultParameterDictionary]$result
}

function Trace-GlobalDefaultsFromDfpFiles {
<#
    .Synopsis
       Trace function to check Get-GlobalDefaultsFromDfpFiles
    .DESCRIPTION
       Returns a resulting settings hashtable

       The Defaults will be loaded according to priority:
        - User settings from userID-file in caller location or current location(?) is prio 1 
        - LogonDomain (or machine name) XML-file in Module location is Prio 2
        - Module name(s) settings is last in order.

    .PARAMETER CallerInvocation
       The invocation object from the caller.
#>
Param(
     [parameter(Position=0,mandatory=$true)]
	 $CallerInvocation
) 
    $result = @{}
    foreach($settingsFile in (Get-SettingsFiles $CallerInvocation ".dfp")) {        
        Write-Host $settingsFile
        
        if (Test-Path "$settingsFile") {
            $settings = Get-Content $settingsFile
            foreach($row in $settings) {
                if (($row -match ":") -and ($row -match "=") -and ($row.Trim().SubString(0,1) -ne "#")) {
                    $key = $settingsFile + ":" + $row.Split('=')[0]
                    #Msg "Key in file $key"
                    if (!$result.ContainsKey($key)) {
                        try {
                            #Add value from XML (OR result from PS-code execution)
                            $result.Add($key,(Invoke-Expression $row.SubString(($row.Split('=')[0]).Length+1)))
                            Write-Host "Added value for $key"
                        } catch {
                            $ex = $PSItem
                            $ex.ErrorDetails = "Err adding $key from $settingsFile. " + $PSItem.Exception.Message
                            throw $ex
                        }                    
                    }
                }
            }
        }
    }
    #Return Parameter Hash
    $result
}

function AppendToHash {
<#
    .Synopsis
        Add content to hashtable with concatination.
    .PARAMETER hash
        The HashTable
    .PARAMETER key
        The key for the value
    .PARAMETER data
        The data to append or add.
    .Notes
        This has much improvements due. In time it may get done.
#>
[CmdletBinding(SupportsShouldProcess = $True)]
Param(
    [parameter(Position=0,mandatory=$true)]
    [HashTable]$hash,
    [parameter(Position=1,mandatory=$true)]
    [string]$key,
    [parameter(Position=2,mandatory=$true)]
    $data
)        
    if ($hash.ContainsKey($key)) {
        Write-Verbose "Add new value to current for [$key]"
        $currentData = $hash[$key]
        
        $hash.Remove($key)
        $hash.Add($key,$currentData + $data)
        
    } else {
        Write-Verbose "Init value for [$key]"
        $hash.Add($key,$data)
    } 
}

<# 
  .SYNOPSIS 
  Create a random password 
 
  .DESCRIPTION 
  The function creates a random password using a given set of available characters. 
  The password is generated with fixed or random length. 
 
  .PARAMETER MinPasswordLength 
  Minimum password length when generating a random length password 
 
  .PARAMETER MaxPasswordLength 
  Maximum password length when generating a random length password 
 
  .PARAMETER PasswordLength 
  Fixed password length 
 
  .PARAMETER InputStrings 
  String array containing sets of available password characters 
 
  .PARAMETER FirstChar 
  Specifies a string containing a character group from which the first character in the password will be generated 
 
  .PARAMETER Count 
  Number of passwords to generate, default = 1 
 
  .EXAMPLE 
  New-RandomPassword -MinPasswordLength 6 -MaxPasswordLength 12 
  Generates a random password fo minimum length 6 andmaximum length 12 characters 
 
  .EXAMPLE 
  New-RandomPassword -PasswordLength 20 
  Generates a password of 20 characters 
 
  .EXAMPLE 
  New-RandomPassword -InputStrings Value -FirstChar Value -Count Value 
  Describe what this call does 
 
  .NOTES 
  Author of function: Thomas Stensitzki 
  Stolen from: https://github.com/Apoc70/GlobalFunctions/blob/master/GlobalFunctions/GlobalFunctions.psm1
  Based on Simon Wahlin's script published here: https://gallery.technet.microsoft.com/scriptcenter/Generate-a-random-and-5c879ed5 
  Story behind: http://blog.simonw.se/powershell-generating-random-password-for-active-directory/

#>
function New-RandomPassword {
[CmdletBinding(DefaultParameterSetName='FixedLength')]
[OutputType([String])] 
param(
  [Parameter(ParameterSetName='RandomLength')]
  [ValidateScript({$_ -gt 0})]
  [Alias('Min')] 
  [int]$MinPasswordLength = 8,
        
  [Parameter(ParameterSetName='RandomLength')]
  [ValidateScript({
          if($_ -ge $MinPasswordLength){$true}
          else{Throw 'Max value cannot be lesser than min value.'}})]
  [Alias('Max')]
  [int]$MaxPasswordLength = 12,

  [Parameter(ParameterSetName='FixedLength')]
  [ValidateRange(1,2147483647)]
  [int]$PasswordLength = 8,
        
  [String[]]$InputStrings = @('abcdefghjkmnpqrstuvwxyz', 'ABCEFGHJKLMNPQRSTUVWXYZ', '23456789', '=+_?!"*@#%&'),

  [String] $FirstChar,
        
  # Specifies number of passwords to generate.
  [ValidateRange(1,2147483647)]
  [int]$Count = 1
)

  Function Get-Seed{
            # Generate a seed for randomization
            $RandomBytes = New-Object -TypeName 'System.Byte[]' 4
            $Random = New-Object -TypeName 'System.Security.Cryptography.RNGCryptoServiceProvider'
            $Random.GetBytes($RandomBytes)
            [BitConverter]::ToUInt32($RandomBytes, 0)
        }

  For($iteration = 1;$iteration -le $Count; $iteration++){
    $Password = @{}
    # Create char arrays containing groups of possible chars
    [char[][]]$CharGroups = $InputStrings

    # Create char array containing all chars
    $AllChars = $CharGroups | ForEach-Object {[Char[]]$_}

    # Set password length
    if($PSCmdlet.ParameterSetName -eq 'RandomLength')
    {
        if($MinPasswordLength -eq $MaxPasswordLength) {
            # If password length is set, use set length
            $PasswordLength = $MinPasswordLength
        }
        else {
            # Otherwise randomize password length
            $PasswordLength = ((Get-Seed) % ($MaxPasswordLength + 1 - $MinPasswordLength)) + $MinPasswordLength
        }
    }

    # If FirstChar is defined, randomize first char in password from that string.
    if($PSBoundParameters.ContainsKey('FirstChar')){
        $Password.Add(0,$FirstChar[((Get-Seed) % $FirstChar.Length)])
    }
    # Randomize one char from each group
    Foreach($Group in $CharGroups) {
        if($Password.Count -lt $PasswordLength) {
            $Index = Get-Seed
            While ($Password.ContainsKey($Index)){
                $Index = Get-Seed                        
            }
            $Password.Add($Index,$Group[((Get-Seed) % $Group.Count)])
        }
    }

    # Fill out with chars from $AllChars
    for($i=$Password.Count;$i -lt $PasswordLength;$i++) {
        $Index = Get-Seed
        While ($Password.ContainsKey($Index)){
            $Index = Get-Seed                        
        }
        $Password.Add($Index,$AllChars[((Get-Seed) % $AllChars.Count)])
    }
  }

  return $(-join ($Password.GetEnumerator() | Sort-Object -Property Name | Select-Object -ExpandProperty Value))

}

function QuerySQL {
<#
    .Synopsis
        Run SQL query and return resulting tables and/or output messages
    .DESCRIPTION
        Invoke a SQL command. For us not able to use the fully featured invoke-sql from the SQL server:

        https://docs.microsoft.com/en-us/powershell/module/sqlserver/invoke-sqlcmd?view=sqlserver-ps
    .PARAMETER Query
        The query to run.
    .PARAMETER Server
        Name of server to connect to (using std authentication)
    .PARAMETER Database
        Name of database to connect to (using std authentication)
    .PARAMETER ConnectionString
        Fully featured connection string
    .NOTES
        For a full feature SQL Admin module: https://dbatools.io/
    #>
    [CmdletBinding(SupportsShouldProcess = $True, DefaultParameterSetName='NamedConnection')]
    Param(
    [parameter(Position=0,mandatory=$true)]
    [string]$Query,       
    [parameter(ParameterSetName='NamedConnection')]
	[string]$Server,
    [parameter(ParameterSetName='NamedConnection')]
	[string]$DataBase,
    [parameter(ParameterSetName='ConnectionString')]
    [string]$ConnectionString
    )
    Begin
    {
        if ([string]::IsNullOrEmpty($ConnectionString)) {
            $ConnectionString="server='$Server';database='$Database';trusted_connection=true;"
        }
        #Establish connection
        $Connection = New-Object System.Data.SQLClient.SQLConnection
        $Connection.ConnectionString = $ConnectionString
        
        [string]$global:tmpInfoMessagesFromSQLcommand = ""
        $InfoHandler = [System.Data.SqlClient.SqlInfoMessageEventHandler]{param($sender, $event) $global:tmpInfoMessagesFromSQLcommand += "$($event.Message)`r`n"}
        $Connection.add_InfoMessage($InfoHandler);
        $Connection.FireInfoMessageEventOnUserErrors = $true;            
        
        $Connection.Open()
        $Command = New-Object System.Data.SQLClient.SQLCommand
        $Command.Connection = $Connection

        $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
        $SqlAdapter.SelectCommand = $Command
    }
    Process
    {
               
        $Command.CommandText = $Query
        $DataSet = New-Object System.Data.DataSet
        $SqlAdapter.Fill($DataSet) | Out-Null

        #Return object with a separate buckets for data and messages.
        #The use of DataSet has some VERY nice features (ask Google if you don't beleive it) 
        #as well as the possibility to return several data tables in one query
        $return = [PSCustomObject]@{
            Messages = $global:tmpInfoMessagesFromSQLcommand
            DataSet = $DataSet
        }

        $return
                
    }
    End
    {
        #Empty tmp-variable
        [string]$global:tmpInfoMessagesFromSQLcommand = $null

        #Close connection
        $Connection.Close()
    }
}

#endregion

#region Unused Code (for reading purposes only)

#Get global defaults to use with $PSDefaultParameterValues
#Returns a Hashtable to load into $PSDefaultParameterValues
#The Defaults will be loaded accoring to priority:
# User settings from userID-file in caller location or current location(?) is prio 1 
# LogonDomain (or machine name) XML-file in Module location is Prio 2
# Module name(s) settings is last in order.
# 
#function GetGlobalDefaultsFromXmlFiles($CallerInvocation) {
#    $result = New-Object System.Management.Automation.DefaultParameterDictionary
#        
#    foreach($settingsFile in (Get-SettingsFiles $CallerInvocation ".xml")) {
#        #Write-Host $settingsFile
#        if (Test-Path "$settingsFile") {
#            [xml]$settings = Get-Content $settingsFile
#            foreach($node in $settings.FirstChild.ChildNodes) {
#                $cmdLetName = $node.Name
#                foreach($setting in $settings.FirstChild.$cmdLetName.ChildNodes) {
#                    
#                    #We cannot have a wildcard in the XML-file so we use the point. (cruddy solution?)
#                    $key = ($cmdLetName).Replace('.','*') + ":" + $setting.Name
#                    if (!$result.ContainsKey($key)) {
#
#                        try {
#                            #Add value from XML (OR result from PS-code execution)
#                            $result.Add($key,(Invoke-Expression $setting.InnerText))
#                        } catch {
#                            $ex = $PSItem
#                            $ex.ErrorDetails = "Err adding $key from $settingsFile. " + $PSItem.Exception.Message
#                            throw $ex
#                        }                    
#                    }
#                }
#            }
#        }
#    }
#
#    #Return Parameter Dictionary 
#    [System.Management.Automation.DefaultParameterDictionary]$result
#}

#These will only return the modules path no matter what!
#function Get-CallerLocation {
#    Split-Path $script:MyInvocation.MyCommand.Path -Parent
#    Split-Path -Leaf $MyInvocation.PSCommandPath  
#}
#
#function InternalModuleTest {
#    Get-CallerLocation
#}
#

#endregion


