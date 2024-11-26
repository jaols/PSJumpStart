<#PSScriptInfo

.VERSION 1.0.1

.GUID 0382d5e0-b1d9-4143-9539-5a6f7a13a5d1

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
    Disables unused Computer accounts
.DESCRIPTION
    Report or handle unused computer accounts in AD.
.PARAMETER monthsUnused
	The number of months a Computer account has not been used. Default in .dpf file.
.PARAMETER searchRootOU
	Root OU-path for search.
.PARAMETER disabledOU
	OU-path to to the OU receiving the disabled accounts.
.PARAMETER ADserver
    Default AD server to use for operations
.PARAMETER writeReport
    Write formatted info to CSV-file. NO ACTION WILL TAKE PLACE.
.PARAMETER UseEventLog
    Standard parameter. Write info to EvenLog as well as std out.    
.NOTES
    Author: Jack Olsson
    Date:   2018-07-14    
    
    Changelog:
    2018-08-01 Added support for retreiving ADserver if not set    

#>
[CmdletBinding(SupportsShouldProcess = $True)]
param (
   [int]$monthsUnused,
   [string]$searchRootOU,
   [string]$disabledOU,
   [string]$ADserver,
   [switch]$writeReport,
   [switch]$useEventLog
)

#region local functions 
function Get-LocalDefaultVariables {
	<#
   .Synopsis
	   Load default arguemts for this PS-file.
   .DESCRIPTION
	   Get setting files according to load order and set variables.
	   Command prompt arguments will override any file settings.
   .PARAMETER defineNew
	   Add ALL variables found in all setting files. This will get full configuration from all json files
   .PARAMETER overWriteExisting
	   Turns the table for variable handling making file content override command line arguments.
   #>
   [CmdletBinding(SupportsShouldProcess = $False)]
   param(
	   [switch]$defineNew,
	   [switch]$overWriteExisting
   )
   foreach($settingsFile in (Get-SettingsFiles  ".json")) {        
	   if (Test-Path $settingsFile) {        
		   Write-Verbose "$($MyInvocation.Mycommand) reading: [$settingsFile]"
		   $DefaultParamters = Get-Content -Path $settingsFile -Encoding UTF8 | ConvertFrom-Json | Set-ValuesFromExpressions
		   ForEach($property in $DefaultParamters.psobject.properties.name) {
			   #Exclude PSDefaultParameterValues ("functionName:Variable":"Value")
			   if (($property).IndexOf(':') -eq -1) {
				   $var = Get-Variable $property -ErrorAction SilentlyContinue
				   $value = $DefaultParamters.$property
				   if (!$var) {
					   if ($defineNew) {
						   Write-Verbose "New Var: $property"
						   $var = New-Variable -Name  $property -Value $value -Scope 1
					   }
				   } else {
					   #We only overwrite non-set values if not forced
					   if (!($var.Value) -or $overWriteExisting)
					   {
						   try {                
							   Write-Verbose "Var: $property" 
							   $var.Value = $value
						   } Catch {
							   $ex = $PSItem
							   $ex.ErrorDetails = "Err adding $property from $settingsFile. " + $PSItem.Exception.Message
							   throw $ex
						   }
					   }
				   }
			   }
		   }
	   } else {
		   Write-Verbose "File not found: [$settingsFile]"
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
		Set-ADComputer -Identity $ComputerObject.SamAccountName -Replace @{info="Disabled [$((Get-Date).ToString())] due to last logon $logonTime"} -Server $ADserver
		
		#Disable Computer
		Disable-ADAccount -Identity $ComputerObject.SamAccountName -Server $ADserver
		
		#Move Computer to DisableOU (if specified)
		if (![string]::IsNullOrEmpty($disabledOU)) {
			Move-ADObject -Identity $ComputerObject -TargetPath $disabledOU -Server $ADserver
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
Import-Module PSJumpStart -Force -MinimumVersion 2.0.0


#Get Local variable default values from external JSON-files
Get-LocalDefaultVariables

#Get global deafult settings when calling modules
$PSDefaultParameterValues = Get-GlobalDefaultsFromJsonFiles $MyInvocation 

#endregion

Msg "Start Execution"

#Prevent disaster if json-file is missing
if ([string]::IsNullOrEmpty($monthsUnused) -or $monthsUnused -eq 0) {
    Msg "Please create a json file for standard values."
    $monthsUnused = 200
}
#Get ADserver to run ALL operations
if ([string]::IsNullOrEmpty($ADserver)) {
    $ADserver = (Get-ADDomainController ).Name
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

