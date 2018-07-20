<#PSScriptInfo

.VERSION 1.0.0

.GUID 0382d5e0-b1d9-4143-9539-5a6f7a13a5d1

.AUTHOR Jack Olsson

.COMPANYNAME 

.COPYRIGHT 

.TAGS 

.LICENSEURI 

.PROJECTURI https://github.com/jaols/PSJumpStart

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES


#>

#Requires -Module PSJumpStart
#Requires -Module ActiveDirectory

<#
.SYNOPSIS
    Disables unused Computer accounts
.DESCRIPTION
    Report or handle unused computer accounts in AD.
.PARAMETER monthsUnused
	The number of months a Computer account has not been used. Default in .dpf file.
.PARAMETER searchRootOU
	Root OU-path for search.
.PARAMETER disabledOU
	OU-path to to the OU receiving the disabled accounts.
.PARAMETER writeReport
    Write formatted info to CSV-file. NO ACTION WILL TAKE PLACE.
.PARAMETER UseEventLog
    Standard parameter. Write info to EvenLog as well as std out.    
.NOTES
    Author: Jack Olsson
    Date:   2018-07-14        

#>
[CmdletBinding(SupportsShouldProcess = $True)]
param (
   [int]$monthsUnused,
   [string]$searchRootOU,
   [string]$disabledOU,
   [switch]$writeReport,
   [switch]$useEventLog
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

function DisableComputer($ComputerObject) {
    if ([string]::IsNullOrEmpty($_.lastLogonTimeStamp)) {
        $logonTime = "not done."
    } else {
	    $logonTime = TimeFromInteger $_.lastLogonTimeStamp
    }
	Msg "Disable Computer $($ComputerObject.SamAccountName) last logged on $logonTime"
	
	if ($pscmdlet.ShouldProcess("$($ComputerObject.SamAccountName)", "Disable Computer")) {		
		#Set "Notes" info 
		Set-ADComputer -Identity $ComputerObject.SamAccountName -Replace @{info="Disabled [$((Get-Date).ToString())] due to last logon $logonTime"} -Server $_ADserver
		
		#Disable Computer
		Disable-ADAccount -Identity $ComputerObject.SamAccountName -Server $_ADserver
		
		#Move Computer to DisableOU (if specified)
		if (![string]::IsNullOrEmpty($disabledOU)) {
			Move-ADObject -Identity $ComputerObject -TargetPath $disabledOU -Server $_ADserver
		}
	} 
}
function ReportData($ComputerObject, $csvFile, $separator) {
	Write-Verbose "Export Computer $($ComputerObject.SamAccountName) last logged on $logonTime"
	$row = ""
	ForEach($prop in $PropertiesToGet) {
		#Write-Host $prop
		if ($ComputerObject.$prop) {
			if ($ComputerObject.$prop.GetType().Name -eq "Int64") {
				$time = TimeFromInteger $($ComputerObject.$prop)
				$row += $time.ToString() + $separator
			} else {
				$row += $($ComputerObject.$prop).ToString() + $separator
			}
		} else {
			$row += $separator
		}
	}
	
	$row | Out-File -Append -FilePath $csvFile	
}
#endregion

#region Init
#CSV-separator 
$separator = ";"
$PropertiesToGet = @("samAccountName","DisplayName","Description","WhenCreated","lastLogonTimeStamp") 
$reportFile = ($CallerInvocation.MyCommand.Definition -replace ".ps1","") + (Get-Date -Format 'yyyyMMdd HHmmss') + ".csv"

if (-not (Get-Module ActiveDirectory)) {
    Import-Module ActiveDirectory
}
Import-Module PSJumpStart -Force


#Get Local variable default values from external DFP-files
GetLocalDefaultsFromDfpFiles($MyInvocation)

#Get global deafult settings when calling modules
$PSDefaultParameterValues = Get-GlobalDefaultsFromDfpFiles $MyInvocation -Verbose:$VerbosePreference

#endregion

Msg "Start Execution"

#Prevent disaster if dfp-file is missing
if ([string]::IsNullOrEmpty($monthsUnused)) {
    $monthsUnused = 200
}
[datetime]$unusedTime = (Get-Date).AddMonths(-$monthsUnused)
Write-Verbose "Get Computers not logon since $unusedTime"
$filter = {Enabled -eq $true -and (LastLogonTimeStamp -lt $unusedTime -or (LastLogonTimeStamp -notlike "*" -and WhenCreated -lt $unusedTime))}

#Prepare report header
if ($writeReport) {
	Msg "Write report to $reportFile"
	$row=""
	ForEach($prop in $PropertiesToGet) {
		$row += $prop + $separator
	}
	$row | Out-File -FilePath $reportFile -Force	
}

Msg "Filter computers last used $unusedTime"
if ([string]::IsNullOrEmpty($searchRootOU)) {
	Get-ADComputer -Filter $filter -Properties $PropertiesToGet | % {		
		if ($writeReport) {
			ReportData $_ $reportFile $separator
		} else {
			DisableComputer $_
		}
	}
} else {
	Get-ADComputer -Filter $filter -Properties $PropertiesToGet -SearchBase $searchRootOU | % {
		if ($writeReport) {
			ReportData $_ $reportFile $separator
		} else {
			DisableComputer $_
		}
	}
}

Msg "End Execution"

