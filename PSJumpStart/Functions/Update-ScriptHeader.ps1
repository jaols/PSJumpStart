

<#
.SYNOPSIS
	Update script header
.DESCRIPTION
	Update parameter list in header from the script argument parameter list
.PARAMETER FullName
	Full path name to file
.PARAMETER Force
	Process signed PowerShell files

.Example
Update-ScriptHeader.ps1 .\MyFile.ps1 

Update parmeter list in header for a single file

.Example 
Get-ChildItem .\ |  .\Update-ScriptHeader.ps1

Process this folder to update headers for all files.

.Example 
Get-ChildItem .\ |  .\Update-ScriptHeader.ps1 -Whatif

Process this folder to check missing/faulty parameters in headers
#>
function Update-ScriptHeader {
    [CmdletBinding(SupportsShouldProcess = $True)]
    param(
        [Parameter(Mandatory = $true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName = $true)]
        [string]$FullName,
        [switch]$Force    
    )
    
    Begin {
        $headerReg = [regex]"^\s*<#[\s\|\S]+#>"
        $skipCommon="[-WhatIf]","[-Confirm]","[-Verbose]"
    }
    
    Process {
        
        #Get-help .\AddFundsByNameToDB.ps1 -Parameter * | ForEach-Object {$_.name}
        Write-Verbose "Input $FullName"
    
        #Only process PS1-file
        if ($FullName.Substring($FullName.Length-3) -ieq "ps1") {
            if (Test-Path $FullName) {
                #We do NOT process signed scripts
                $signed = Get-AuthenticodeSignature -FilePath $FullName 
                if ($signed.Status -eq "NotSigned" -or $Force) {
                    
                    $hlp=$null
                    $hlp = Get-Help -Name $FullName -Parameter * -ErrorAction SilentlyContinue                
                    
                    if ($hlp -and $hlp.Count -gt 0) {
                        $scriptContent = Get-Content $FullName -Raw
                        
                        $orgHeader=($headerReg.Matches($scriptContent)).Value
                            
                        $newScript = [System.Text.StringBuilder]::new()
                        
                        $found=$true
                        foreach($line in ($orgHeader -split [Environment]::NewLine)) {
                            if ($line -eq "#>") {
                                break
                            }
                    
                            if ($line.IndexOf(".PARAMETER") -gt -1) {
                                $found=$false
                                for ($n = 0;$n -lt $hlp.Count; $n++) {
                                    if ($line.IndexOf($hlp[$n].Name) -gt -1) {
                                        $found=$true
                                        continue
                                    }
                                }
                                if ($found) {
                                    [void]$newScript.AppendLine($line)
                                }
                            } else {                                                                
                                if ($found) {
                                    [void]$newScript.AppendLine($line)
                                } else {
                                    $found=$true
                                }                                
                            }
                        }
                        
                        for ($n = 0;$n -lt $hlp.Count; $n++) {
                            if (!($skipCommon -icontains "[-" + $hlp[$n].Name + "]")) {
                                if ($orgHeader.IndexOf(".PARAMETER " + $hlp[$n].Name) -eq -1) {
                                    Write-Verbose ("Adding missing parameter: " + $hlp[$n].Name)
                                    [void]$newScript.Append(".PARAMETER ")
                                    [void]$newScript.AppendLine($hlp[$n].Name)
                                    [void]$newScript.Append("`t")
                                    [void]$newScript.AppendLine($hlp[$n].Name)
                                }
                            }
                        }
                        [void]$newScript.Append("#>")
                    
                        if ($newScript.ToString() -ne $orgHeader) {
                            if ($PSCmdlet.ShouldProcess($FullName,"Set new header")) {
                                Write-Host "Set new header in $FullName"
                                [void]$newScript.Append($scriptContent.SubString($orgHeader.Length+1))
                                $newScript.ToString() | Out-File $FullName -Force
                            } else {
                                $newScript.ToString()
                            }
                        } else {
                            Write-Verbose "No header diff for $FullName"
                        }   
                    } else {
                        Write-Verbose "No arguments found in help for $FullName"
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