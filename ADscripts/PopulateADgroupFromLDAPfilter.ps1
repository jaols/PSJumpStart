<#PSScriptInfo

.VERSION 1.0.1

.GUID 68d2ca31-4f91-4914-a5ff-60c50445236f

.AUTHOR Jack Olsson

.COMPANYNAME 

.COPYRIGHT 

.TAGS 

.LICENSEURI 

.PROJECTURI https://github.com/jaols/PSJumpStart

.ICONURI 

.EXTERNALMODULEDEPENDENCIES ActiveDirectory

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES

#>

#Requires -Module PSJumpStart

<#
.SYNOPSIS
    Populate group members for a group from LDAPfilter
.DESCRIPTION    
	The script will search for principals (AD-objects) in AD according to LDAP-filter, then add any missing principals AND remove extra principals
	If -WhatIf switch is used you will see information on actions but NO ACTION WILL TAKE PLACE.
	Use the standard flag -Verbose to get extended information on execution.
	Use the CMD-file to launch as a scheduled task. Log informaiton is written to std out as the CMD will redirect this to a log-file.
.PARAMETER TargetGroup
	The group name to populate members for
.PARAMETER LDAPfilter
	Search filter to use for finding users
.PARAMETER searchRootOU
	Root OU-path for search.
.PARAMETER ADserver
    Default AD server to use for operations
.EXAMPLE	
	NAME -TargetGroup ALLUsers -LDAPfilter "(&(objectCategory=person)(objectClass=user)(!userAccountControl:1.2.840.113556.1.4.803:=2))"
	Set all enabled users as member of the group ALLUsers
.EXAMPLE	
	NAME -TargetGroup "MailUsers" -LDAPfilter "(&(objectCategory=person)(objectClass=user)(mail=*)(!userAccountControl:1.2.840.113556.1.4.803:=2))"	
	Set all enabled users WITH a mail address as member of the group MailUsers.
.EXAMPLE	
	NAME -TargetGroup AutoEnroll_MachineCertificate -LDAPfilter "(&(objectCategory=computer)(departmentNumber=*))"	
	Set all computers with the departmentNumber attribute set as member of AutoEnroll_MachineCertificate
.NOTES
    You may want to use dfp files for default values. If so you need to remove the Mandatory flags in the script parameter list.

    Author: Jack Olsson
    Date:   2018-07-24    

    Changelog:
    2018-08-01  Added support for retreiving ADserver if not set 
                Moved default setting from param to code..

#>
[CmdletBinding(SupportsShouldProcess = $True)]
param (
   	[Parameter(Mandatory=$true)]
   	[string]$TargetGroup,   
   	[Parameter(Mandatory=$true)]
	[string]$LDAPfilter,	
	[string]$searchRootOU, 
	[string]$ADserver
   	
)
#region local functions 
function GetLocalDefaultsFromDfpFiles($CallerInvocation) {        
    #Load script default settings
    foreach($settingsFile in (Get-SettingsFiles $CallerInvocation ".dfp")) {
        Write-Verbose "GetLocalDefaultsFromDfpFiles: [$settingsFile]"
        if (Test-Path $settingsFile) {        
            $settings = Get-Content $settingsFile
            #Enumerate settingsfile rows
            foreach($row in $settings) {
                #Remarked lines are not processed
                if (($row -match "=") -and ($row.Trim().SubString(0,1) -ne "#")) {
                    $key = $row.Split('=')[0]                            
                    $var = Get-Variable $key -ErrorAction SilentlyContinue
                    if ($var -and !($var.Value))
                    {
                        try {                                            
                            $var.Value = Invoke-Expression $row.SubString($key.Length+1)
                            Write-Verbose "GetLocalDefaultsFromDfpFiles: $key = $($var.Value)" 
                        } Catch {
                            $ex = $PSItem
                            $ex.ErrorDetails = "Err adding $key from $settingsFile. " + $PSItem.Exception.Message
                            throw $ex
                        }
                    }                   
                }
            }
        }
    }
}
#endregion

#region Init
if (-not (Get-Module ActiveDirectory)) {
    Import-Module ActiveDirectory
}
if (-not (Get-Module PSJumpStart)) {
    Import-Module PSJumpStart
}

#Get Local variable default values from external DFP-files
GetLocalDefaultsFromDfpFiles($MyInvocation)

#Get global deafult settings when calling modules
$PSDefaultParameterValues = Get-GlobalDefaultsFromDfpFiles $MyInvocation -Verbose:$VerbosePreference

#endregion

Msg "Start Execution"
#Get default OU if not used in dfp files or arguments
if ([string]::IsNullOrEmpty($ADserver)) {
    $searchRootOU = ([adsi]"LDAP://rootdse").defaultNamingContext
}
#Get ADserver to run ALL operations
if ([string]::IsNullOrEmpty($ADserver)) {
    $ADserver = (Get-ADDomainController ).Name
}

Write-Verbose "Get current members for $TargetGroup"

$currentMembers = Get-ADGroupMember -Identity $TargetGroup -Server $ADserver
if ([string]::IsNullOrEmpty($currentMembers)) {
	Msg "Group has no members"
	$currentMembers=@()	
} else {
	Msg "Group has $($currentMembers.Count) current members"
}

Write-Verbose "Extract users in $searchRootOU using $LDAPfilter"
$members = Get-ADObject -LDAPFilter $LDAPfilter -SearchBase $searchRootOU -Server $ADserver
Msg "Found $($members.Count) members from query"

$newMembers = @()
foreach($member in $members) {
	$isMember = $false
	foreach($current in $currentMembers) {
		if ($member.ObjectGUID -eq $current.ObjectGUID) {
			$isMember = $true
		}
	}	
	if (!$isMember) {		
		Write-Verbose("Add new member: " + $member.DistinguishedName)
		$newMembers += ($member.ObjectGUID).ToString()
		#$newMembers += $member.DistinguishedName		 
	}
}

if ($newMembers.Count -gt 0) {	
	Msg "Set $($newMembers.Count) new members"
    if ($pscmdlet.ShouldProcess($TargetGroup,"Add-ADGroupMember")) {
	    Add-ADGroupMember -Identity $TargetGroup -Members $newMembers -Server $ADserver	
    }
}

$removeMembers = @()
foreach($current in $currentMembers) {
	$remove = $true
	foreach($member in $members) {
		if ($member.ObjectGUID -eq $current.ObjectGUID) {
			$remove = $false
		}
	}
	if ($remove) {
		Write-Verbose("Remove member: " + $current.DistinguishedName)
		$removeMembers += $($current.DistinguishedName)		
	}
}

if ($removeMembers.Count -gt 0) {	
	Msg "Remove $($removeMembers.Count) members"
    if ($pscmdlet.ShouldProcess($TargetGroup,"Remove-ADGroupMember")) {
	    Remove-ADGroupMember -Identity $TargetGroup -Members $removeMembers	-Confirm:$false
    }
}

Msg "End Execution"


