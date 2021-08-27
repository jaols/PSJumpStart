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
      $TemplateFolder="$PSScriptRoot\..\Templates"
      Write-Verbose "Copy template(s) from $TemplateFolder"
  
      if ([string]::IsNullOrEmpty($Name)) {
          Get-ChildItem "$TemplateFolder" | Copy-Item -Destination $Destination
      } else {
          Get-ChildItem "$TemplateFolder" -Filter "$Name" | Copy-Item -Destination $Destination
      }
  }