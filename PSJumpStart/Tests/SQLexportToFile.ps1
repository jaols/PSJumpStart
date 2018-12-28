[CmdletBinding(SupportsShouldProcess = $True)]
Param(    
)
#region Init

#Load default arguemts for this script from the dfp setting files.
#Command prompt arguments will override any settings
function GetLocalDefaultsFromDfpFiles($CallerInvocation) {        
    #Load script default settings
    foreach($settingsFile in (Get-SettingsFiles $CallerInvocation ".dfp")) {
        #Write-Host "File: [$settingsFile]"
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
                        } Catch {
                            $ex = $PSItem
                            $ex.ErrorDetails = "Err adding $key from $settingsFile. " + $PSItem.Exception.Message
                            throw $ex
                        }
                    }
                   #Write-Host "$($var.Value)"
                }
            }
        }
    }
}


#Load the module
get-module PSJumpStart | Remove-Module;
Import-Module PSJumpStart

#Get Local variable default values from external DFP-files
GetLocalDefaultsFromDfpFiles($MyInvocation)

#Get global deafult settings when calling modules
$PSDefaultParameterValues = Get-GlobalDefaultsFromDfpFiles($MyInvocation)
#endregion

Msg "Start Execution"    

Msg "Test a stored procedure call"

$query="Exec [dbo].[CustOrdersOrders] 'OCEAN'" 
Invoke-SqlQuery $query | Select-Object -ExpandProperty DataSet | Select-Object -ExpandProperty Tables | Out-DataTableToFile

Msg "SQL query with multiple output tables"

$query="Select LastName,FirstName FROM [dbo].[Employees] 
    Select * FROM [dbo].[Shippers] "
        
    Invoke-SqlQuery $query | Select-Object -ExpandProperty DataSet | Select-Object -ExpandProperty Tables | ForEach-Object {
    Out-DataTableToFile -FileName "$($_.TableName) Mixed double.csv" -DataTable $_ 
}

Msg "End Execution"
