[CmdletBinding(SupportsShouldProcess = $True)]
Param(    
)
#region Init

#Load the module
Import-Module PSJumpStart -MinimumVersion 2.0.0 -Force

#Get global deafult settings when calling modules
$PSDefaultParameterValues = Get-GlobalDefaultsFromJsonFiles($MyInvocation)
#endregion

Write-Message "Start Execution"

Write-Message "List All templates"
Find-PSTemplate | Out-Default

Write-Message "List 'argument' templates"
Find-PSTemplate -Name "*arg*" | Out-Default

Write-Message "Copy PSJumpStart templates to current location"
#Copy-PSTemplate -Name "PSJumpStart*"

Write-Message "End Execution"
