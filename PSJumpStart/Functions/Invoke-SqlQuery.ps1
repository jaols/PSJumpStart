function Invoke-SqlQuery {
    <#
        .Synopsis
            Run SQL query and return resulting tables and/or output messages
        .DESCRIPTION
            Invoke a SQL command. For us not able to use the fully featured invoke-sql from the SQL server:
    
            https://docs.microsoft.com/en-us/powershell/module/sqlserver/invoke-sqlcmd?view=sqlserver-ps
        .PARAMETER Query
            The query to run.
        .PARAMETER Server
            Name of server to connect to (using std authentication)
        .PARAMETER Database
            Name of database to connect to (using std authentication)
        .PARAMETER ConnectionString
            Fully featured connection string
        .NOTES
            For a full feature SQL Admin module: https://dbatools.io/
        #>
        [CmdletBinding(DefaultParameterSetName='NamedConnection')]
        Param(
        [parameter(Position=0,mandatory=$true)]
        [string]$Query,       
        [parameter(ParameterSetName='NamedConnection')]
        [string]$Server,
        [parameter(ParameterSetName='NamedConnection')]
        [string]$DataBase,
        [parameter(ParameterSetName='ConnectionString')]
        [string]$ConnectionString
        )
        Begin
        {
            if ([string]::IsNullOrEmpty($ConnectionString)) {
                $ConnectionString="server='$Server';database='$Database';trusted_connection=true;"
            }
            #Establish connection
            $Connection = New-Object System.Data.SQLClient.SQLConnection
            $Connection.ConnectionString = $ConnectionString
            
            [string]$global:tmpInfoMessagesFromSQLcommand = ""
            $InfoHandler = [System.Data.SqlClient.SqlInfoMessageEventHandler]{param($sender, $event) $global:tmpInfoMessagesFromSQLcommand += "$($event.Message)`r`n"}
            $Connection.add_InfoMessage($InfoHandler);
            $Connection.FireInfoMessageEventOnUserErrors = $true;            
            
            $Connection.Open()
            $Command = New-Object System.Data.SQLClient.SQLCommand
            $Command.Connection = $Connection
    
            $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
            $SqlAdapter.SelectCommand = $Command
        }
        Process
        {
                   
            $Command.CommandText = $Query
            $DataSet = New-Object System.Data.DataSet
            $SqlAdapter.Fill($DataSet) | Out-Null
    
            #Return object with a separate buckets for data and messages.
            #The use of DataSet has some VERY nice features (ask Google if you don't beleive it) 
            #as well as the possibility to return several data tables in one query
            $return = [PSCustomObject]@{
                Messages = $global:tmpInfoMessagesFromSQLcommand
                DataSet = $DataSet
            }
    
            $return
                    
        }
        End
        {
            #Empty tmp-variable
            [string]$global:tmpInfoMessagesFromSQLcommand = $null
    
            #Close connection
            $Connection.Close()
        }
    }
    