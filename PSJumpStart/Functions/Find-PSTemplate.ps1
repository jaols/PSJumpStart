function Find-PSTemplate {
    <#
    .SYNOPSIS
        List template files
    .DESCRIPTION
        List available template files
    .PARAMETER Name
        Name of template(s) 
    #>
    [CmdletBinding()]
        Param(     
            [string]$Name
        )
        $TemplateFolder="$PSScriptRoot\..\Templates"
        Write-Verbose "Find templates in $TemplateFolder"
    
        if ([string]::IsNullOrEmpty($Name)) {
            $list = Get-ChildItem "$TemplateFolder"
        } else {
            $list = Get-ChildItem "$TemplateFolder" -Filter "$Name"
        }
    
        ForEach($template in $list) {
            $Description = ""
            if ($template.Extension -ieq ".ps1") {
                $Description = (Get-help $template.FullName -ShowWindow:$false).Description[0].Text
            }
            
            [PSCustomObject]@{
                Name = $template.Name
                Description = $Description
            }
        }
    }