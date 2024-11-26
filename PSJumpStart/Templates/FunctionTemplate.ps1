 function Trace-Template {
 <#
   .Synopsis
      Template 
   .DESCRIPTION
      This basic template has support for Write-Verbose, -WhatIf and whatnot.   
   .PARAMETER InputObject
      Input parameter containing things to process
   .Example 
      

   .Notes
      Author:
       
#>
[CmdletBinding(SupportsShouldProcess = $True)]
[OutputType("PJSTraceTemplate")]
param (   
   [PSCustomObject]$InputObject
)

if ($pscmdlet.ShouldProcess("ActiveCode", "Run Code")) {
   foreach($property in $InputObject.psobject.properties.name )
   {      
      [PSCustomObject]@{
        PSTypeName = "PJSTraceTemplate" #Output type may be used for Format-commands
        Parent=$Input
        PropertyName=$property
        PropertyValue=$Input.$property
      }
   }
}

}

 