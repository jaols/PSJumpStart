Function Get-AccessCredential {
    <#
    .Synopsis
        Retreive a PsCredential object for access to a system or session-object. 
    .DESCRIPTION
        A cached credential will be used if a credential XML-file is found. If no file is found the user need to provide info interactivally. The provided
        username and password is saved for later use. 
        The saved credential file can only be decrypted by current user on current machine.
    .PARAMETER AccessName
        System name to retreive access to. This will be used in the saved file name.
    .PARAMETER CredFilesPath
        Folder to read/save credentials from/to.
    #.PARAMETER MachineProtectionScope
    #    Only lock credential file to current computer. NOTE:ALL users with access to the computer may retreive credential info.
    .PARAMETER Renew
        Force renewal of credential file.

    .Notes
    
    #>
    [CmdletBinding()]
    PARAM(        
        [string]$AccessName,
        [string]$CredFilesPath,
        #[switch]$MachineProtectionScope,
        [switch]$Renew
    )

    #The MachineProtectionScope option is NOT recomended as ALL users with access to this machine may decrypt credentials
    #if ($MachineProtectionScope) {
    #    $machineKey = [System.Text.Encoding]::UTF8.GetBytes((Get-ItemProperty registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography\ -Name MachineGuid).MachineGUID.Replace('-',''))
    #    $CredFileName = $env:ComputerName + "$AccessName.xml"
    #} else {
        $CredFileName = $env:ComputerName + "." + $env:UserName + "$AccessName.xml"
    #}

    if ([string]::IsNullOrEmpty($CredFilesPath)) { 
        $credFile = $CredFileName
    } else {
        $credFile = $CredFilesPath + "\" + $CredFileName
    }
    
    Write-Verbose "Using credfile $credFile"

    if ((Test-Path $credFile) -and (!$renew)) {
        try {
            $creds = Import-Clixml $credFile
            #if ($MachineProtectionScope) {                
            #    $machinePwd = ConvertTo-SecureString -String $creds.Password -Key $machineKey
            #    $creds = New-Object System.Management.Automation.PSCredential($creds.UserName, $machinePwd)
            #}
        } catch {
            #Renew credentials if cache failed
            Write-Verbose "Renew credentials due to error"
            Get-AccessCredential @PsBoundParameters -renew
        }
    } else {
        #Retreive credentials interactivally
        #$creds=Get-Credential
        $creds = $host.ui.PromptForCredential("Get access credentials for $AccessName", "Please enter your access credentials", "", "")
        if (-not $creds) {
            Throw "No credentials provided in dialog!"
        }
        
        Write-Verbose "Save new credentials"
        #if ($MachineProtectionScope) {
        #    $userPwd = ConvertFrom-SecureString -SecureString $($creds.Password) -Key $machineKey
        #    @{UserName=$creds.UserName;Password=$userPwd} | Export-Clixml -Path $credFile -Force
        #} else {
            $creds | Export-Clixml -Path $credFile -Force
        #}        
    }
    return $creds
}