[CmdletBinding(SupportsShouldProcess = $True)]
Param(    
)
#region Init
#region local functions
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
        [parameter(Position=0,mandatory=$true)]
        $CallerInvocation,
        [switch]$defineNew,
        [switch]$overWriteExisting
    )
    foreach($settingsFile in (Get-SettingsFiles $CallerInvocation ".json")) {        
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

function dumpDBresult($dbResult) {
    #Show any query result messages from the SQL-execution (error in SQL syntax)
    if ($dbResult.Messages) {
        Msg ("Messages from Query: " + $dbResult.Messages)
    } 

    Msg("Number of tables: " + $dbResult.DataSet.Tables.Count)
    ForEach($table in $dbResult.DataSet.Tables) {
        $n++
        Msg("Table $n contains " + $table.Rows.Count + " rows.")
        $names = ""
        ForEach($column in $table.Columns) {
            $names += "[" + $column.ColumnName + "]"
        }
        Msg "and has these columns $names"
    }
    
}

#endregion

#Load the module
get-module PSJumpStart | Remove-Module;
Import-Module PSJumpStart -MinimumVersion 1.3.0

#Get Local variable default values from external DFP-files
Get-LocalDefaultVariables($MyInvocation)

#Get global deafult settings when calling modules
$PSDefaultParameterValues = Get-GlobalDefaultsFromJsonFiles($MyInvocation)
#endregion


Msg "Start Execution"    

Msg "Test a stored procedure call"

$query="Exec [dbo].[CustOrdersOrders] 'OCEAN'"
$res = Invoke-SqlQuery $query
dumpDBresult $res

Msg "Test SQL query with double table result"

$query="Print 'Hello world' 
    Select LastName,FirstName FROM [dbo].[Employees] 
    Select * FROM [dbo].[Shippers] "
        
dumpDBresult (Invoke-SqlQuery $query) 

Msg "Run ERROR query"
$query = "Select Whatever from NoWay"
$res = Invoke-SqlQuery $query
dumpDBresult $res


Msg "End Execution"
