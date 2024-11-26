[CmdletBinding(SupportsShouldProcess = $False)]
Param(    
)
#region Init

function Get-LocalDefaultVariables {
     <#
    .Synopsis
        Load default arguemts for this PS-file.
    .DESCRIPTION
        Get setting files according to load order and set variables.
        Command prompt arguments will override any file settings
    .PARAMETER CallerInvocation
        $MyInvocation of calling code session            
    .PARAMETER defineNew
        Add ALL variables found in setting files
    .PARAMETER overWriteExisting
        Turns the table for variable handling file content will override command line arguments                                
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


#Load the module
get-module PSJumpStart | Remove-Module;
Import-Module PSJumpStart -MinimumVersion 2.0.0

#Get Local variable default values from external JSON-files
Get-LocalDefaultVariables

#Get global deafult settings when calling modules
$PSDefaultParameterValues = Get-GlobalDefaultsFromJsonFiles($MyInvocation)
#endregion

Write-Message "Start Execution"    

Write-Message "Test a stored procedure call"

$query="Exec [dbo].[CustOrdersOrders] 'OCEAN'" 
$data = Invoke-SqlQuery $query
if ($data.Messages) {
    Write-Message$data.Messages -Type Warning
} else {
    Write-Message("Save result in " + $PSDefaultParameterValues["Out-DataTableToFile:FileName"])
    $data.DataSet | Select-Object -ExpandProperty Tables | Out-DataTableToFile
}

Write-Message "SQL query with multiple output tables "

$query="Select LastName,FirstName FROM [dbo].[Employees] 
    Select * FROM [dbo].[Shippers] "
        
$data = Invoke-SqlQuery $query 
if ($data.Messages) {
    Write-Message$data.Messages -Type Warning
} else {
    $data.DataSet | Select-Object -ExpandProperty Tables | ForEach-Object {
        Write-Message "Save to file $($_.TableName) Mixed double.csv"
        Out-DataTableToFile -FileName "$($_.TableName) Mixed double.csv" -DataTable $_ 
    }     
}

Write-Message "End Execution"
