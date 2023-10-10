function Wait-OnMutex
{
    param(
        [parameter(Mandatory = $true)][string] $MutexId,
        [parameter(Mandatory = $true)][int]$WaitCycleCount,
        [parameter(Mandatory = $true)][int]$WaitTimeMilliseconds
    )

    try
    {
        $MutexInstance = New-Object System.Threading.Mutex -ArgumentList 'false', $MutexId

        for ($i = 0; $i -lt $WaitCycleCount; $i++) 
        {
            if ($MutexInstance.WaitOne($WaitTimeMilliseconds)) {                
                return $MutexInstance
                break
            }
            #Write-Host "." -NoNewline
            
        }
        throw "Wait-OnMutex has reached max waiting time"
        
    } 
    catch [System.Threading.AbandonedMutexException] 
    {
        $MutexInstance = New-Object System.Threading.Mutex -ArgumentList 'false', $MutexId        
        return Wait-OnMutex -MutexId $MutexId
    }
}
