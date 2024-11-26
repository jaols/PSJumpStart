
#enable verbose messaging in the psm1 file
if ($MyInvocation.line -match "-verbose") {
    $orgVerbose = $VerbosePreference
    $VerbosePreference = [System.Management.Automation.ActionPreference]::Continue
}

#Get Local lib function script folder OR current folder
$LocalLibPath=$MyInvocation.PSScriptRoot
if ([string]::IsNullOrEmpty($LocalLibPath)) {            
    $LocalLibPath=$PWD.Path
} 
Write-Verbose "Local loading path is: $LocalLibPath"

#Get Local DLL files
$AddTypesDlls = @(Get-ChildItem -Path $LocalLibPath\LocalLib\*.dll -ErrorAction SilentlyContinue)
#Get Local module lib DLL files (but exclude locally loaded DLLs)
$AddTypesDlls += @(Get-ChildItem -Path $PSScriptRoot\LocalLib\*.dll -Exclude ($AddTypesDlls | Select-Object -ExpandProperty Name)  -ErrorAction SilentlyContinue)

if ($AddTypesDlls) {
    #Write-Verbose "Local loading path is: $LocalLibPath"
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

#Get functions from local lib in script folder
$FunctionFiles = @(Get-ChildItem -Path $LocalLibPath\LocalLib\*.ps1 -ErrorAction SilentlyContinue)
#Get Local module lib function files
$FunctionFiles += @(Get-ChildItem -Path $PSScriptRoot\LocalLib\*.ps1 -ErrorAction SilentlyContinue -Exclude ($FunctionFiles | Select-Object -ExpandProperty Name))
#Get PSJumpStart function files
$FunctionFiles += @(Get-ChildItem -Path $PSScriptRoot\Functions\*.ps1 -ErrorAction SilentlyContinue -Exclude ($FunctionFiles | Select-Object -ExpandProperty Name))

#Import PSJumpstart functions
foreach($Import in $FunctionFiles) {
    try {
        Write-Verbose "Load $($Import.FullName)"
        . $Import.FullName
        #$functionNames += ($Import.Name).Replace(".ps1","")
    }
    catch {
        Write-Error -Message "Failed to import function $($Import.FullName): $_"
    }
}

#Reset Verbose mode
if ($MyInvocation.line -match "-verbose") {
    $VerbosePreference = $orgVerbose
}

$PSJumpStartModulePath = $PSScriptRoot
#Export-ModuleMember -Function $functionNames
Export-ModuleMember -Function * -Alias * -Variable PSJumpStartModulePath

