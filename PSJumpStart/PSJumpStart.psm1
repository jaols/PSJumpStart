
#enable verbose messaging in the psm1 file
if ($MyInvocation.line -match "-verbose") {
    $VerbosePreference = [System.Management.Automation.ActionPreference]::Continue
}

#Get Local lib function script folder OR current folder
$LocalLibPath=$MyInvocation.PSScriptRoot
if ([string]::IsNullOrEmpty($LocalLibPath)) {    
    $LocalLibPath=$PWD.Path    
} 

#Get Local DLL files
$AddTypesDlls = @(Get-ChildItem -Path $LocalLibPath\LocalLib\*.dll -ErrorAction SilentlyContinue)
#Get Local module lib DLL files (but exclude locally loaded DLLs)
$AddTypesDlls += @(Get-ChildItem -Path $PSScriptRoot\LocalLib\*.dll -Exclude ($AddTypesDlls | Select-Object -ExpandProperty Name)  -ErrorAction SilentlyContinue)

if ($AddTypesDlls) {
    Add-Type -Path ($AddTypesDlls | Select-Object -ExpandProperty FullName) -Verbose:$VerbosePreference
}

#Get Local TypeData files
$TypeData = @(Get-ChildItem -Path $LocalLibPath\TypeData\*.ps1xml -ErrorAction SilentlyContinue)
$TypeData += @(Get-ChildItem -Path $PSScriptRoot\TypeData\*.ps1xml -ErrorAction SilentlyContinue -Exclude ($TypeData | Select-Object -ExpandProperty Name))
if ($TypeData) {
    Update-TypeData -PrependPath $TypeData -Verbose:$VerbosePreference
}

#Get Local Formats files
$FormatData = @(Get-ChildItem -Path $LocalLibPath\Formats\*Format.ps1xml -ErrorAction SilentlyContinue)
$FormatData += @(Get-ChildItem -Path $PSScriptRoot\Formats\*Format.ps1xml -ErrorAction SilentlyContinue -Exclude ($FormatData | Select-Object -ExpandProperty Name))
if ($FormatData) {
    Update-FormatData -PrependPath $FormatData -Verbose:$VerbosePreference
}


#Get PSJumpStart function files
$FunctionLib = @(Get-ChildItem -Path $PSScriptRoot\Functions\*.ps1 -ErrorAction SilentlyContinue)
#Get Local module lib function files
$LocalModuleLib = @(Get-ChildItem -Path $PSScriptRoot\LocalLib\*.ps1 -ErrorAction SilentlyContinue)
#Get functions from local lib in script folder
$LocalLib = @(Get-ChildItem -Path $LocalLibPath\LocalLib\*.ps1 -ErrorAction SilentlyContinue)

#$functionNames = @()

#Import PSJumpstart functions
foreach($Import in $FunctionLib) {
    try {
        . $Import.FullName
        #$functionNames += ($Import.Name).Replace(".ps1","")
    }
    catch {
        Write-Error -Message "Failed to import function $($Import.FullName): $_"
    }
}
#Import local lib functions (override any PSJumpstart modules)
foreach($Import in $LocalModuleLib) {
    try {
        . $Import.FullName
        #$functionNames += ($Import.Name).Replace(".ps1","")
    }
    catch {
        Write-Error -Message "Failed to import function $($Import.FullName): $_"
    }
}

#Import local lib functions (override any functions)
foreach($Import in $LocalLib) {
    try {        
        . $Import.FullName
        #$functionNames += ($Import.Name).Replace(".ps1","")
    }
    catch {
        Write-Error -Message "Failed to import function $($Import.FullName): $_"
    }
}

#Export-ModuleMember -Function $functionNames
Export-ModuleMember -Function *
