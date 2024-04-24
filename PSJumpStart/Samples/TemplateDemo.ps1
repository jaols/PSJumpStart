[CmdletBinding(SupportsShouldProcess = $True)]
Param(    
)
#region Init

#Load the module
get-module PSJumpStart | Remove-Module;
Import-Module PSJumpStart -MinimumVersion 1.3.0

#Get global deafult settings when calling modules
$PSDefaultParameterValues = Get-GlobalDefaultsFromJsonFiles($MyInvocation)
#endregion

Msg "Start Execution"

Msg "List All templates"
Find-PSTemplate | Out-Default

Msg "List 'argument' templates"
Find-PSTemplate -Name "*arg*" | Out-Default

Msg "Copy PSJumpStart templates to current location"
#Copy-PSTemplate -Name "PSJumpStart*"

Msg "End Execution"
