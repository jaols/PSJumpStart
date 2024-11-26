function Write-Message {
    <#
        .Synopsis
           Main output function.
        .DESCRIPTION
           Writes messages to file log and/or eventvwr std-out/std-err OR host.
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
           Write-Message "The secret is OUT"
    
           Writes "The secret is OUT" to std-out as "INFORMATION" message
        .EXAMPLE
           Write-Message "This was NO good" "ERROR"
    
           Writes the message to std-error
        .EXAMPLE
           Write-Message "This was NO good" "ERROR" -useEventLog
    
           Writes message to console (Write-Host) and to the windows Eventlog.
        .EXAMPLE
           Write-Message "Write this to file" -useFileLog
    
           Writes message to console (Write-Host) and to the standard log file name.
        #>
    [CmdletBinding(DefaultParameterSetName = "Message")]
    [Alias("Msg")]
    Param(
        [parameter(Position = 0, mandatory = $true, ValueFromPipeline=$true)]
        $Message,
        [parameter(Position = 1, mandatory = $false)]
        [string]$Type = "INFORMATION",        
        [switch]$useEventLog,
        [string]$EventLogName = "Application",
        [int]$EventId = 4695,
        [switch]$useFileLog,
        [string]$logFile,
        [string]$logFilePath
    )
    
    #Retreive caller script/commnad name and location
    $callStack = Get-PSCallStack | Select-Object ScriptName
    for ($i = $callStack.Count-1; $i -gt 0; $i--) {                        
        if (![string]::IsNullOrEmpty($callStack[$i].ScriptName)) {
            $callerLocation=Split-Path -parent $callStack[$i].ScriptName
            $callerName=Split-Path -leaf $callStack[$i].ScriptName
            break
        }
    }

    #Use name from $MyInvocation
    #$callerName = Split-Path -Leaf $MyInvocation.PSCommandPath  
    
    $logstring = (Get-Date).ToString() + ";" + $Message
        
    if ($useEventLog.IsPresent) {
        Write-Verbose "Write-Message:Use eventlog"
        #We will get an error if not running as administrator
        try {
            if (![system.diagnostics.eventlog]::SourceExists($callerName)) {
                [system.diagnostics.EventLog]::CreateEventSource($callerName, $EventLogName)
            }
            Write-EventLog -LogName $EventLogName -Source $callerName -EntryType $Type -Message $Message -EventId $EventId -Category 0
        }
        catch {
            Write-Error "ERROR;Run as ADMINISTRATOR;$($PSItem.Exception.Message)"
        }        
    }
    
    if ($useFileLog.IsPresent) {
        Write-Verbose "Write-Message:Use logfile"
                
        if ([string]::IsNullOrEmpty($logFilePath)) {
            $logFilePath = $callerLocation
        }
                            
        if ([string]::IsNullOrEmpty($logFile)) {
            $logfile = $logFilePath + "\" + $callerName + "." + (Get-Date -Format 'yyyy-MM') + ".log"
        }
        elseif (!$logFile.Contains("\")) {
            $logfile = $logFilePath + "\" + $logfile
        }                        
    
        #Write to log file
        $stream = [System.IO.File]::AppendText($logFile)
        $stream.WriteLine($logstring)
        $stream.close()
    
    }
    
    if ($useFileLog.IsPresent -or $useEventLog.IsPresent) {
        #Write to console
        Write-Host "$Type;$logstring"
    }
    else {

        Write-Verbose "Write-Message:Use std-Out/std-Err"
        if ($Type -match "Err") {
            Write-Error "$Type;$logstring"
        } else {
            Write-Output "$Type;$logstring"
        }
    }
}
    