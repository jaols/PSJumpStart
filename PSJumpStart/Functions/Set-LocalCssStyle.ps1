function Set-LocalCssStyle {
    <#
    .SYNOPSIS
        Set local stylesheet content for existing html code
    .DESCRIPTION
        Inserts a <style> tag with CssStyle content
    .PARAMETER CssStyle
        Stylesheet string or file name with style sheet content
    .PARAMETER HtmlCode
        Html code to process.
    .Example
        Get-Process | ConvertTo-Html -Property Name,Path,Company | Set-LocalCssStyle -CssStyle "th {background-color: #5D7B9D;color: white;}
            tr:nth-child(even) {background: #D0D3D4}
            tr:nth-child(odd) {background: #FFF}
            tr:hover {background-color: #a6a6a6;}"

        Add a header style and alternating row style for the ConvertTo-Html output.
    .Example        
        Get-Process | ConvertTo-Html -Property Name,Path,Company | Set-LocalCssStyle -CssStyle C:\styles\tablestyle.css | Out-File C:\styles\process.html

        Add stylesheet file content to ConvertTo-Html output.
    #>

    [CmdletBinding()]
     param(         
         [String]$CssStyle,
         [String]$ReplaceTag,
         [Parameter(ValueFromPipeline=$true)]
         $HtmlCode
     )
 
 Begin {
     if ([string]::IsNullOrWhiteSpace($ReplaceTag)) {
         $ReplaceTag = "<head>"
     }
     if (Test-Path $CssStyle) {
         $CssStyle = Get-Content -Path $CssStyle
     }
             
     $Replace =  New-Object Text.StringBuilder
     [void]$Replace.AppendLine($ReplaceTag)
     [void]$Replace.AppendLine("<style>")
     [void]$Replace.AppendLine($CssStyle)
     [void]$Replace.AppendLine("</style>")
     
 }
 
 
 Process {    
     $result += $HtmlCode -replace $ReplaceTag,$Replace.ToString()            
 }
 
 End {
     return $result
 }
 
 }
 