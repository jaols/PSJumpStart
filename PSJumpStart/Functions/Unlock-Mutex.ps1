function Unlock-Mutex {
    param(
        [parameter(Mandatory = $true)][string] $MutexId
    )
    try
    {
        [Threading.Mutex]$MutexInstance = [Threading.Mutex]::OpenExisting($MutexId)
        $MutexInstance.ReleaseMutex()
    } catch {
        #If we get an error the Mutax is no more and we are happy!        
        return
    }

    #Call myself as we has seen failed ReleaseMutex() calls!!!
    Unlock-Mutex -MutexId $MutexId
}
