function Out-DataTableToFile {
    <#
    .SYNOPSIS
        Dump a datatable to CSV-file OR XML-file
    .DESCRIPTION
        Not much to add. It's fairly simple.
    .PARAMETER CSVseparator
           Character to use for CSV separation.
    .PARAMETER CSVnoheader
        Do not export header (column names) to CSV.
    .PARAMETER Header
        Use custom header (NOT column names) in CSV.
    .PARAMETER Encoding
        Specifies the type of character encoding used in the file. Valid values are "Unicode", "UTF7", "UTF8", "UTF32","ASCII", "BigEndianUnicode", "Default", and "OEM".
    .PARAMETER FileName
        Name of target file fo export.
    .PARAMETER Xml
        Export to XML instead of CSV.
    .NOTES
        Author: Jack Olsson
        Date:   2016-04-21
    }
    #>
    param (
       [Parameter(Mandatory=$true,
                  ValueFromPipeline=$true,
                  ValueFromPipelineByPropertyName=$true)]
       [System.Data.Datatable]$DataTable,
       [Parameter(Mandatory=$true,              
                  ValueFromPipelineByPropertyName=$true)]
       [string]$FileName,   
       [string]$CSVseparator,
       [switch]$CSVnoheader,
       [string]$Header,
       [string]$Encoding,
       [switch]$xml
       
    )
    
    Begin {
    }
    Process {
       Write-Verbose $DataTable.TableName
        if ($xml.IsPresent) {
            ($DataTable | ConvertTo-XML -NoTypeInformation).Save($FileName)	
        } else {
            if ($CSVnoheader.IsPresent) {
                ($DataTable | ConvertTo-Csv -Delimiter $CSVseparator -NoTypeInformation) -replace "`"", "" |  Select-Object -Skip 1 | `
                    Out-File -Encoding $Encoding -Force $FileName
            } elseif (-not [string]::IsNullOrEmpty($Header)) {
                $Header | Out-File -Encoding $Encoding -Force $FileName
                ($DataTable | ConvertTo-Csv -Delimiter $CSVseparator -NoTypeInformation) -replace "`"", "" |  Select-Object -Skip 1 | `
                    Out-File -Encoding $Encoding -Append $FileName 
     
            } else {
                ($DataTable | ConvertTo-Csv -Delimiter $CSVseparator -NoTypeInformation) -replace "`"", "" | `
                    Out-File -Encoding $Encoding -Force $FileName
            }
        }
    }
    
    End {
    }
    }
    
    