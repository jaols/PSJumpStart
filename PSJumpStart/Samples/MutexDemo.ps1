[CmdletBinding()]
param(
    [int]$NestedNum
)

#region Init
#region local functions
function Get-LocalDefaultVariables {
     <#
    .Synopsis
        Load default arguemts for this PS-file.
    .DESCRIPTION
        Get setting files according to load order and set variables.
        Command prompt arguments will override any file settings
    .PARAMETER CallerInvocation
        $MyInvocation of calling code session            
    .PARAMETER defineNew
        Add ALL variables found in setting files
    .PARAMETER overWriteExisting
        Turns the table for variable handling file content will override command line arguments                                
    #>
    [CmdletBinding(SupportsShouldProcess = $False)]
    param(
        [parameter(Position=0,mandatory=$true)]
        $CallerInvocation,
        [switch]$defineNew,
        [switch]$overWriteExisting
    )
    foreach($settingsFile in (Get-SettingsFiles $CallerInvocation ".json")) {        
        if (Test-Path $settingsFile) {        
            Write-Verbose "$($MyInvocation.Mycommand) reading: [$settingsFile]"
            $DefaultParamters = Get-Content -Path $settingsFile -Encoding UTF8 | ConvertFrom-Json | Set-ValuesFromExpressions             
            ForEach($property in $DefaultParamters.psobject.properties.name) {
                #Exclude PSDefaultParameterValues ("functionName:Variable":"Value")
                if (($property).IndexOf(':') -eq -1) {
                    $var = Get-Variable $property -ErrorAction SilentlyContinue
                    $value = $DefaultParamters.$property
                    if (!$var) {
                        if ($defineNew) {
                            Write-Verbose "New Var: $property"
                            $var = New-Variable -Name  $property -Value $value -Scope 1
                        }
                    } else {
                        #We only overwrite non-set values if not forced
                        if (!($var.Value) -or $overWriteExisting)
                        {
                            try {                
                                Write-Verbose "Var: $property" 
                                $var.Value = $value
                            } Catch {
                                $ex = $PSItem
                                $ex.ErrorDetails = "Err adding $property from $settingsFile. " + $PSItem.Exception.Message
                                throw $ex
                            }
                        }
                    }
                }
            }
        } else {
            Write-Verbose "File not found: [$settingsFile]"
        }
    }
}
#endregion
Remove-Module PSJumpStart
Import-Module PSJumpStart -Force -MinimumVersion 1.3.0

#Retreive variables for this script (overwrite input arguments with -overWriteExisting).
Get-LocalDefaultVariables -CallerInvocation $MyInvocation 
#Get default paramters when calling functions (for example std-adserver)
$PSDefaultParameterValues = Get-GlobalDefaultsFromJsonFiles $MyInvocation 

#endregion

Msg "Session $NestedNum - Start Execution"

#NOTE: Start two PS-windows 4 better demo

#Same mutex id for all instances
$MutexId = "de9a280d-ce61-4eca-adba-70332a68e065"

#Create or wait for mutex
Msg "Session $NestedNum - Wait for mutex release"
$mutex = Wait-OnMutex $MutexId -WaitCycleCount 100 -WaitTimeMilliseconds 1000


#region Sensitive code!! May only run one instance at a time!
if ($NestedNum -lt 1) {    
    for ($i = 1; $i -lt 6; $i++) {                
        Msg "Session $NestedNum - Call myself with argument -NestedNum  $i"
        & $MyInvocation.MyCommand.Definition -NestedNum $i
    }
} else {
    Msg "Session $NestedNum - wait 3 seconds"
    Start-Sleep -Seconds 3
}
#endregion


Msg "Session $NestedNum - Release Mutex and cleanup last error"
Unlock-Mutex -MutexId $MutexId
$Error.RemoveAt(0)


Msg "Session $NestedNum - End Execution"
