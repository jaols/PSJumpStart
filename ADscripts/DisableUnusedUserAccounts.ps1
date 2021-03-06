<#PSScriptInfo

.VERSION 1.0.1

.GUID c054c9d5-d69d-4354-bb5f-2543f855eb75

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
    Disables unused user accounts
.DESCRIPTION
    This script will search for User accounts not used in -monthsUnused months.
    Found users will be disabled and moved to the -disabledOU (if parameter is present)
.PARAMETER searchRootOU
	Root OU-path for search.
.PARAMETER ADserver
    Default AD server to use for operations
.PARAMETER monthsUnused
	The number of months a user account has not been used.
.PARAMETER disabledOU
	OU-path to to the OU receiving the disabled accounts.
.PARAMETER exceptionGroup
	Do NOT touch members of this group.
.PARAMETER writeReport
    Write formatted info to CSV-file. NO ACTION WILL TAKE PLACE.
.PARAMETER UseEventLog
    Standard parameter. Write info to EvenLog as well as std out.
.NOTES
    Author: Jack Olsson
    Date:   2018-07-20

    Changelog:
    2018-08-01 Added support for retreiving ADserver if not set    
#>
[CmdletBinding(SupportsShouldProcess = $True)]
param (   	
   [string]$searchRootOU,
   [string]$ADserver,
   [int]$monthsUnused,
   [string]$disabledOU,
   [string]$exceptionGroup,
   [switch]$writeReport
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
function DisableUser($userObject) {
	$logonTime = ""
	if ($_.lastLogonTimeStamp) {
		$logonTime = TimeFromInteger $_.lastLogonTimeStamp
	}
	Msg "Disable user $($userObject.SamAccountName) last logged on $logonTime"
	
	if ($pscmdlet.ShouldProcess("$($userObject.SamAccountName)", "Disable user")) {		
		#Set "Notes" info 
		Set-ADUser -Identity $userObject.SamAccountName -Replace @{comment="Disabled [$((Get-Date).ToString())] due to last logon $logonTime"} -Server $ADserver
		
		#Disable user
		Disable-ADAccount -Identity $userObject.SamAccountName -Server $ADserver
		
		#Move user to DisableOU (if specified)
		if (![string]::IsNullOrEmpty($disabledOU)) {
			Move-ADObject -Identity $userObject -TargetPath $disabledOU -Server $ADserver
		}
	} 
}
function ReportData($userObject, $csvFile, $separator) {
	Write-Verbose "Export user $($userObject.SamAccountName) last logged on $logonTime"
	$row = ""
	ForEach($prop in $PropertiesToGet) {
		#Write-Host $prop
		if ($userObject.$prop) {
			if ($userObject.$prop.GetType().Name -eq "Int64") {
				$time = TimeFromInteger $($userObject.$prop)
				$row += $time.ToString() + $separator
			} else {
				$row += $($userObject.$prop).ToString() + $separator
			}
		} else {
			$row += $separator
		}
	}
	
	$row | Out-File -Append -FilePath $csvFile	
}
function TimeFromInteger {
	Param(
	 [parameter(mandatory=$true)]
	 $TimeStamp
    )

    [datetime]::FromFileTime($TimeStamp)
}

function TimeToInteger {
	Param(
	 [parameter(mandatory=$true)]
	 [DateTime]$TimeStamp
    )

    $TimeStamp.ToFileTime()
}
#endregion

#region Init
$CSVseparator = ";"
$PropertiesToGet = @("samAccountName","DisplayName","Description","WhenCreated","lastLogonTimeStamp")
 
$reportFile = "$_scriptPath\$_scriptName - " + (Get-Date -Format 'yyyyMMdd HHmmss') + ".csv"

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
#Prevent disaster if dfp-file is missing
if ([string]::IsNullOrEmpty($monthsUnused) -or $monthsUnused -eq 0) {
    Msg "Please create a dfp file for standard values."
    $monthsUnused = 200
}
#Get ADserver to run ALL operations
if ([string]::IsNullOrEmpty($ADserver)) {
    $ADserver = (Get-ADDomainController ).Name
}


if (![string]::IsNullOrEmpty($exceptionGroup)) {
	$untouchables = Get-ADGroupMember -Identity $exceptionGroup -Recursive | Select -ExpandProperty samAccountName
}

[datetime]$unusedTime = (Get-Date).AddMonths(-$monthsUnused)
Write-Verbose "Get users not logon since $unusedTime"
#$filter = "(lastLogonTimeStamp >= $($unusedTime.ToFileTime()))"
#$filter = {LastLogonTimeStamp -lt $unusedTime -and Enabled -eq $true}
$filter = {Enabled -eq $true -and (LastLogonTimeStamp -lt $unusedTime -or (LastLogonTimeStamp -notlike "*" -and WhenCreated -lt $unusedTime))}

#Prepare report header
if ($writeReport) {
	Msg "Write report to $reportFile"
	$row=""
	ForEach($prop in $PropertiesToGet) {
		$row += $prop + $CSVseparator
	}
	$row | Out-File -FilePath $reportFile -Force	
}

Msg "Filter users last used $unusedTime"
if ([string]::IsNullOrEmpty($searchRootOU)) {
	#Get-ADUser -LDAPFilter $filter -Properties $PropertiesToGet | % {
	Get-ADUser -Filter $filter -Properties $PropertiesToGet | % {		
		if ($untouchables -notcontains $($_.SamAccountName)) {
			if ($writeReport) {
				ReportData $_ $reportFile $CSVseparator
			} else {
				DisableUser $_		
			}
		}
	}
} else {
	Get-ADUser -Filter $filter -Properties $PropertiesToGet -SearchBase $searchRootOU | % {
		if ($untouchables -notcontains $($_.SamAccountName)) {
			if ($writeReport) {
				ReportData $_ $reportFile $CSVseparator
			} else {
				DisableUser $_
			}
		}
	}
}

Msg "End Execution"


