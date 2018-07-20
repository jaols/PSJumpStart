 <#
.Synopsis
    Sign scripts
.DESCRIPTION
    Sign target script(s) using existing certificate. If existing certificate is missing a new is generated.
.PARAMETER Path
   	Target path for file to sign or folder name to sign all files.
.PARAMETER FileType
   	Suffix for files to sign. Default is ".ps1"
.PARAMETER Recurse
   If Path is a folder the signijng will be done recursive
.Notes
    Author: Jack Olsson
    Changes: 2018-07-11 First draft
    
    2018-07-20
    Added support for file types to sign.
#>
[CmdletBinding(SupportsShouldProcess = $True)]
param (
    [Parameter(Mandatory = $true,
               ValueFromPipelineByPropertyName=$true)]
    [string]$Path,
    [string]$FileType = ".ps1",
    [switch]$Recurse
)

#region Init

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition

if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!"
    Break
}

#endregion

#region local functions
function New-CodeSigningCert {
<#
    .SYNOPSIS
        Get a certificate!
    .DESCRIPTION
        
#>
[CmdletBinding()]
param()
    Write-Verbose "Create a certificate to use for signing powershell scripts"
    $selfsigncert = New-SelfSignedCertificate `
                -Subject "CN=PowerShell Code Signing" `
                -FriendlyName "Local self-signed code signing certificate" `
                -KeyAlgorithm RSA `
                -KeyLength 2048 `
                -Type CodeSigningCert `
                -CertStoreLocation Cert:\LocalMachine\My\

    Write-Verbose "Move the root cert into Trusted Root CAs"
    Move-Item "Cert:\LocalMachine\My\$($selfsigncert.Thumbprint)" Cert:\LocalMachine\Root

    Write-Verbose "Obtain a reference to the code signing cert in Trusted Root"
    $cert = (Get-ChildItem -Path "Cert:\LocalMachine\Root\$($selfsigncert.Thumbprint)")
    $cert
}
#end region

Write-Output "Start Execution"

Write-Verbose "Enumerate Cert:\LocalMachine\Root"
Get-ChildItem -Path Cert:\LocalMachine\Root -CodeSigningCert | ForEach {       
    if ($_.Verify()) {
        Write-Verbose "Found existing certificate Cert:\LocalMachine\Root\$($_.Thumbprint)"
        $cert = $_        
    }
}

if ($cert -eq $null) {
    Write-Verbose "No valid certificate found. Generating a new one."
    
    if ($pscmdlet.ShouldProcess("N/A", "New-CodeSigningCert")) {
        $cert = New-CodeSigningCert
        Write-Verbose "Copy cert into Trusted publishers"
        Export-Certificate  -Cert $cert -FilePath ".\$($selfsigncert.Thumbprint).cer"
        Import-Certificate -FilePath ".\$($selfsigncert.Thumbprint).cer" -CertStoreLocation Cert:\LocalMachine\TrustedPublisher
        Remove-Item -Path ".\$($selfsigncert.Thumbprint).cer" -Force
    }
}

Get-ChildItem -Path $Path -Filter "*$FileType" -Recurse:$Recurse.IsPresent | ForEach {    
    if ($pscmdlet.ShouldProcess($_.FullName, "Set-AuthenticodeSignature")) {
        $result = Set-AuthenticodeSignature $_.FullName -Certificate $cert
        Write-Output "$($result.Status);$($_.FullName)"
    }
}



Write-Output "End Execution"