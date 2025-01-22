﻿
<#
.Synopsis
    Get files from GitHub to build an non-module based PowerShell Jumpstart environment
.DESCRIPTION
    Download a set of files from GitHub based on json input file. You may cherrypick from any 
    repository to build a solution environment.
    
.PARAMETER FilesToGetJson
   	Json file containing files to get from GitHub
.PARAMETER trgFolder
   	Target folder for main files and folders defult is current folder
.PARAMETER libraryName
	Name of subfolder for function files. Defult is 'Functions'
.Notes
    Author: 
    Changes:
#>
[CmdletBinding(SupportsShouldProcess = $True)]
param (
    #[Parameter(Mandatory = $true)]
    [string]$FilesToGetJson=".\GetJumpstartFiles.json",
    [string]$trgFolder,
    [string]$libraryName="Functions"
)

#region Local Functions
function Set-ValuesFromExpressions {
    <#
        .Synopsis
            Returns the input object populated by Expression executions
        .DESCRIPTION
            Enumerates a PSObject properties for code to run. The code to run is placed in brackets.
            For example "(Get-Process -Name 'NotePad')"
                        
        .PARAMETER inputData
            Typically a PSCustomObject generated by using: Get-Content "someJsonFile.json" | ConvertFrom-Json 
        
        .EXAMPLE
            $DriveInfo = New-Object psobject -Prop ([ordered] @{Name=((Get-PSDrive).Name); Free = ((Get-PSDrive).Free); Used = ((Get-PSDrive).Used)})
            
            $DriveInfo2 = New-Object psobject -Prop ([ordered] @{Name="((Get-PSDrive).Name)"; Free = "((Get-PSDrive).Free)"; Used = "((Get-PSDrive).Used)"})

            #$DriveInfo sames as $DriveInfo2 if piped to Set-ValuesFromExpressions
            $DriveInfo2 | Set-ValuesFromExpressions
    
        .EXAMPLE
            $json='{"paths": ["($ExecutionContext.SessionState.Path.CurrentLocation.Path + ''\\logs'')","C:\\Temp"]}'
            
            $location=$json | ConvertFrom-Json | Set-ValuesFromExpressions

        .Notes
            Prefix a value with space to use a brackets in a JSON file - "note":" (This is NOT an expression)"
            
    #>
    [CmdletBinding(SupportsShouldProcess = $False)]
    param (
        [Parameter(Mandatory,ValueFromPipeline)]
        [PSObject]$inputData
    )
    process {
        foreach($property in $inputData.psobject.properties.name) {

            #if ($property -eq "answer1") {
            #    $haltOnThis=""
            #}

            #Write-Verbose ($property + ":" + $inputData.$property.GetType().Name)
            switch -Regex ($inputData.$property.GetType().Name) {
                'Object$' { 
                    Write-Verbose ("Recurse object: " + $inputData.$property)
                    $inputData.$property=Set-ValuesFromExpressions -inputData $inputData.$property
                    Break
                }
                '\[\]$' {
                    Write-Verbose ("Enum array: " + $property)
                    for ($n=0;$n -lt $inputData.$property.count ; $n++) {
                        Write-Verbose ("Evaluating prop: $property [" + $inputData.$property[$n].GetType().Name + "]")
                        if ($inputData.$property[$n].GetType().Name -match "Object$") {
                            Write-Verbose ("Recurse object: $property [$n]")
                            $inputData.$property[$n]=Set-ValuesFromExpressions -inputData $inputData.$property[$n]
                        } else {
                            if ($inputData.$property[$n].GetType().Name -eq "String" -and $inputData.$property[$n].SubString(0,1) -eq '(') {
                                Write-Verbose ("Expression: " + $inputData.$property[$n])
                                $inputData.$property[$n]=(Invoke-Expression -Command $inputData.$property[$n])
                            }
                        }
                    }
                    Break
                }
                'String' {
                    if ($inputData.$property.SubString(0,1) -eq '(') {
                        Write-Verbose ("Expression: " + $inputData.$property)
                        $inputData.$property=(Invoke-Expression -Command $inputData.$property)                        
                    }
                    Break
                }
            }
            
        }
        return $inputData
    }
    
}
#endregion

Add-Type -assembly "system.io.compression.filesystem"

if ([string]::IsNullOrEmpty($trgFolder)) {
    $trgFolder = Split-Path -Parent $MyInvocation.MyCommand.Definition
}

$cfg = Get-Content -Path $FilesToGetJson -Encoding UTF8 | ConvertFrom-Json | Set-ValuesFromExpressions
ForEach($src in $cfg.psobject.properties.name) {
    ForEach($file in $cfg.$src.Files) {        
        $downloadArgs=@{
            Uri=$cfg.$src.Url + "/$file"
            OutFile=($trgFolder + "\" + $cfg.$src.LocalFolder + "\" + $file)
        }
        
        try {        
            Invoke-WebRequest @downloadArgs
        } catch {
            Write-Host "Failed to download [$file] from [$($downloadArgs.Uri)]: $PSItem"
            continue
        }
        
        Write-Host "File [$file] downloaded from [$($downloadArgs.Uri)]"

        If ($file -match 'zip$') {
            #If file is a zipfile we need to unzip it???
            $zip = [io.compression.zipfile]::OpenRead($downloadArgs.OutFile)
            $zPath = $trgFolder + "\" + $cfg.$src.LocalFolder + "\"
            foreach($zfile in ($zip.Entries | where-object { $_.Name.Length -gt 0})) {
                $zTrgFile = $zPath + $zfile.FullName.Substring($zfile.FullName.IndexOf('/')+1)
                if (!(Test-Path (Split-Path -Parent $zTrgFile))) {
                    md (Split-Path -Parent $zTrgFile)
                }
                if (!(Test-Path $zTrgFile)) {
                    Write-Host "Extract to file $zTrgFile"
                    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($zfile,$zTrgFile)
                }
            }
            $zip.Dispose()
            Remove-Item $downloadArgs.OutFile
        }
    }
}
