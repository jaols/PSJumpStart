[CmdletBinding()]
param(
    [int]$NestedNum
)

#region Init
#region local functions
function Get-LocalDefaultVariables {
    [CmdletBinding(SupportsShouldProcess = $False)]
    param(
        [parameter(Position=0,mandatory=$true)]
        $CallerInvocation,
        [switch]$defineNew,
        [switch]$overWriteExisting
    )
    foreach($settingsFile in (Get-SettingsFiles $CallerInvocation ".json")) {        
        if (Test-Path $settingsFile) {        
            Write-Verbose "Reading file: [$settingsFile]"
            $DefaultParamters = Get-Content -Path $settingsFile -Encoding UTF8 | ConvertFrom-Json
            ForEach($prop in $DefaultParamters | Get-Member -MemberType NoteProperty) {        
                
                if (($prop.Name).IndexOf(':') -eq -1) {
                    $key=$prop.Name
                    $var = Get-Variable $key -ErrorAction SilentlyContinue
                    $value = $DefaultParamters.($prop.Name)                    
                    if (!$var) {
                        if ($defineNew) {
                            Write-Verbose "New Var: $key" 
                            if ($value.GetType().Name -eq "String" -and $value.SubString(0,1) -eq '(') {
                                $var = New-Variable -Name  $key -Value (Invoke-Expression $Value) -Scope 1
                            } else {
                                $var = New-Variable -Name  $key -Value $value -Scope 1
                            }
                        }
                    } else {

                        #We only overwrite non-set values if not forced
                        if (!($var.Value) -or $overWriteExisting)
                        {
                            try {                
                                Write-Verbose "Var: $key" 
                                if ($value.GetType().Name -eq "String" -and $value.SubString(0,1) -eq '(') {
                                    $var.Value = Invoke-Expression $value
                                } else {
                                    $var.Value = $value
                                }
                            } Catch {
                                $ex = $PSItem
                                $ex.ErrorDetails = "Err adding $key from $settingsFile. " + $PSItem.Exception.Message
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
Import-Module PSJumpStart -Force -MinimumVersion 1.2.0

#Retreive variables for this script (overwrite input arguments with -overWriteExisting).
Get-LocalDefaultVariables -CallerInvocation $MyInvocation 
#Get default paramters when calling functions (for example std-adserver)
$PSDefaultParameterValues = Get-GlobalDefaultsFromJsonFiles $MyInvocation 

#endregion

Msg "Session $NestedNum - Start Execution"

#NOTE: Start two PS-windows 4 better testing

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
