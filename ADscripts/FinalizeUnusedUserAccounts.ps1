<#PSScriptInfo

.VERSION 1.0.1

.GUID b347c6d7-2af6-4cf3-ae62-89ceece60f7e

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
    Finalize removal of unused user accounts
.DESCRIPTION
    This script will search for users disabled by DisableUnusedUserAccounts and remove them after they have been disabled for the given period.    
.PARAMETER searchRootOU
	Root OU-path for search.
.PARAMETER ADserver
    Default AD server to use for operations
.PARAMETER monthsDisabled
	The number of months a user account has not been disabled.
.PARAMETER exceptionGroup
	Do NOT touch members of this group.
.PARAMETER writeReport
    Write formatted info to CSV-file. NO ACTION WILL TAKE PLACE.

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
   [int]$monthsDisabled,   
   [string]$exceptionGroup,
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

function KillUser($userObject) {
	Msg "Kill user: $($userObject.SamAccountName)"
	
	if ($pscmdlet.ShouldProcess("$($userObject.SamAccountName)", "Kill user")) {		
        
        if (Test-Path $($userObject.HomeDirectory)) {
		    #Remove home folder
            Write-Verbose "KillUser:Remove folder $($userObject.HomeDirectory)"
            Remove-Item -Path $($userObject.HomeDirectory) -Force
        }

        if (Test-Path $($userObject.ProfilePath)) {
            #Remove profile folder
            Write-Verbose "KillUser:Remove folder $($userObject.ProfilePath)"
            Remove-Item -Path $($userObject.ProfilePath) -Force
        }
        
        #Kill AD-object
        Write-Verbose "KillUser:Remove user $($userObject.distinguishedName)"
        Remove-ADUser -Identity $userObject

    }	 
}

function GetDateDisabled($inputString) {
    
    if ($inputstring -match "(Disabled \[)(.*)(\].*)") {
        $result = Get-Date($Matches[2])
    } else {
        $result = Get-Date
    }

    Write-Verbose "GetDateDisabled:$result <- $inputString"
    $result
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
$PropertiesToGet = @("samAccountName","Comment","HomeDirectory","ProfilePath")
 
$reportFile = "$_scriptPath\$_scriptName - " + (Get-Date -Format 'yyyyMMdd HHmmss') + ".csv"

if (-not (Get-Module ActiveDirectory)) {
    Import-Module ActiveDirectory
}
if (-not (Get-Module PSJumpStart)) {
    Import-Module PSJumpStart -MinimumVersion 2.0.0
}

#Get Local variable default values from external JSON-files
Get-LocalDefaultVariables 

#Get global deafult settings when calling modules
$PSDefaultParameterValues = Get-GlobalDefaultsFromJsonFiles $MyInvocation 

#endregion


Msg "Start Execution"
#Prevent disaster if json-file is missing
if ([string]::IsNullOrEmpty($monthsDisabled) -or $monthsDisabled -eq 0) {
    Msg "Please create a json file for standard values."
    $monthsDisabled = 200
}

#Get ADserver to run ALL operations
if ([string]::IsNullOrEmpty($ADserver)) {
    $ADserver = (Get-ADDomainController ).Name
}

[datetime]$unusedTime = (Get-Date).AddMonths(-$monthsDisabled)
Write-Verbose "Get users disabled since $unusedTime"

if (![string]::IsNullOrEmpty($exceptionGroup)) {
	$untouchables = Get-ADGroupMember -Identity $exceptionGroup -Recursive | Select -ExpandProperty samAccountName
}

$filter = {Enabled -eq $false -and comment -like "Disabled [*" -and comment -like "*due to last logon*"}

#Prepare report header
if ($writeReport) {
	Msg "Write report to $reportFile"
	$row=""
	ForEach($prop in $PropertiesToGet) {
		$row += $prop + ";"
	}
	$row | Out-File -FilePath $reportFile -Force	
}

Msg "User filter $filter"
if ([string]::IsNullOrEmpty($searchRootOU)) {
	#Get-ADUser -LDAPFilter $filter -Properties $PropertiesToGet | % {
	Get-ADUser -Filter $filter -Properties $PropertiesToGet | % {		
		if ($untouchables -notcontains $($_.SamAccountName)) {
            $disabledDate = GetDateDisabled $($_.Comment)
            if ($disabledDate -lt $unusedTime) {
			    if ($writeReport) {
			    	ReportData $_ $reportFile
			    } else {
			    	KillUser $_
			    }
            }
		}
	}
} else {
	Get-ADUser -Filter $filter -Properties $PropertiesToGet -SearchBase $searchRootOU | % {
		if ($untouchables -notcontains $($_.SamAccountName)) {
			if ($writeReport) {
				ReportData $_ $reportFile
			} else {
				$_.SamAccountName 
				$_.comment
				KillUser $_ 				
			}
		}
	}
}


Msg "End Execution"
