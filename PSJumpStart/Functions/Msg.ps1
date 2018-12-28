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
            Write-Verbose "Msg:Use eventlog"
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
                Write-Verbose "Msg:Use logfile"
                #Write to console
                Write-Host "$Type;$logstring"
                
                if ([string]::IsNullOrEmpty($logFilePath)) {
                    $logFilePath = $MyInvocation.PSCommandPath | Split-Path -Parent
                }
                            
                if ([string]::IsNullOrEmpty($logFile)) {
                    $logfile =  $logFilePath + "\" + ($MyInvocation.PSCommandPath | Split-Path -Leaf) + "." + (Get-Date -Format 'yyyy-MM') + ".log"
                } elseif (!$logFile.Contains("\")) {
                    $logfile =  $logFilePath + "\" + $logfile
                }                        
    
                #Write to log file
                $stream = [System.IO.File]::AppendText($logFile)
                $stream.WriteLine($logstring)
                $stream.close()
    
            } else {
                Write-Verbose "Msg:Use std-Out/std-Err"
                if ($Type -match "Err") {
                    Write-Error "$Type;$logstring"
                } else {
                    Write-Output "$Type;$logstring"
                }
            }    
        }
    }
    