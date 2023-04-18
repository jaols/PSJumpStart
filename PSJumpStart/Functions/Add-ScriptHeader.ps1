<#
.SYNOPSIS
	Add a header to a Powershell file(s)
.DESCRIPTION
	Generate a header using the script argument parameter list
.PARAMETER FullName
	Full path name to file
.PARAMETER Synopsis
	Standard synopsis to use
.PARAMETER Description
	Standard description to use
.PARAMETER Force
	Process signed PowerShell files

.Example
Add-ScriptHeader.ps1 .\MyFile.ps1 -Description "This will handle my stuff" -Synopsis "MyFile"

Add a standard header for a single file

.Example 
Get-ChildItem .\ |  .\Add-ScriptHeader.ps1 -Description "Auto-generated header"

Process this folder to add headers to all files.
.Example 
Get-ChildItem .\ |  .\Add-ScriptHeader.ps1 -WhatIf

Process this folder to check all files for missing headers
#>
function Add-ScriptHeader {
    [CmdletBinding(SupportsShouldProcess = $True)]
    param(
        [Parameter(Mandatory = $true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName = $true)]
        [string]$FullName,
        [string]$Synopsis,
        [string]$Description,
        [switch]$Force    
    )
    
    Begin {
        $argReg = [regex]"\[-\w+\]*"
        $skipCommon="[-WhatIf]","[-Confirm]","[-Verbose]"
    }
    
    Process {        
        Write-Verbose "Input $FullName"
    
        #Only process PS1-file
        if ($FullName.Substring($FullName.Length-3) -ieq "ps1") {
            if (Test-Path $FullName) {
                #We do NOT process signed scripts
                $signed = Get-AuthenticodeSignature -FilePath $FullName
                if ($signed.Status -eq "NotSigned" -or $Force) {
                    $hlp = Get-Help -Name $FullName -Full
                    
                    #No header help in place if help text length is same as synopsis
                    if ($hlp.Length -eq $hlp.Synopsis.Length) {                 
                        Write-Host "Add header to $FullName"
    
                        $newScript = [System.Text.StringBuilder]::new()
                        [void]$newScript.AppendLine("<#")
                        [void]$newScript.AppendLine(".SYNOPSIS")
                        if ([string]::IsNullOrEmpty($Synopsis)) {
                            [void]$newScript.AppendLine("`t$($hlp.Name)")
                        } else {
                            [void]$newScript.AppendLine("`t$Synopsis")
                        }
                        [void]$newScript.AppendLine(".DESCRIPTION")
                        [void]$newScript.AppendLine("`t$Description")
                                                           
                        $cmdArgs = $argReg.Matches($hlp.Synopsis)
                                                                
                        foreach($cmdArg in $cmdArgs) {
                            if (!($skipCommon -icontains $cmdArg.Value)) {
                                $param=$cmdArg.Value.TrimStart('[-').TrimEnd(']')
                                [void]$newScript.Append(".PARAMETER ")
                                [void]$newScript.AppendLine("$param")
                                [void]$newScript.AppendLine("`t$param")
                            }
                        }
                        [void]$newScript.AppendLine("#>")
    
                        if ($PSCmdlet.ShouldProcess($FullName,'Append header to file ')) {
                            [void]$newScript.Append($(Get-Content $FullName -Raw))                
                            $newScript.ToString() | Out-File $FullName -Force
                        } else {
                            Write-Host $newScript.ToString()
                        }
    
                    }
                } else {
                    Write-Host "Skip signed file $FullName. Signed files need to be re-signed if changed."
                }
            }
        }
        
    }
    
    End {
    }
}