function Copy-PSTemplate {
    <#
      .SYNOPSIS
          List template files
      .DESCRIPTION
          List available template files
      .PARAMETER Name
          Name of template(s) 
      .PARAMETER 
          Name of template(s) 
  #>  
  [CmdletBinding()]
      Param(     
          [string]$Name,
          [string]$Destination
      )
      Write-Verbose "Copy template(s) from $PSScriptRoot\Templates"
  
      if ([string]::IsNullOrEmpty($Name)) {
          Get-ChildItem "$PSScriptRoot\Templates" | Copy-Item -Destination $Destination
      } else {
          Get-ChildItem "$PSScriptRoot\Templates" -Filter "$Name" | Copy-Item -Destination $Destination
      }
  }