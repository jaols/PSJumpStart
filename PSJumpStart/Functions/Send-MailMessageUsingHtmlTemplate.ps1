Function Send-MailMessageUsingHtmlTemplate {
    <#
        .Synopsis
            Send mail using a html file template
        .DESCRIPTION
            Replace content in provided template using input hashtable.        
        .PARAMETER MailTo
            Receiver of the mail
        .PARAMETER MailFrom
            Name of the sender
        .PARAMETER Subject
            The subject line of the mail
        .PARAMETER TemplateFile
            The full path to the html template file 
        .PARAMETER ReplacementHash
            Hashtable to use for replace strings in the template. The hash key is used for search and replace
        .PARAMETER Attachements
            A string array of file names to attach with the mail
        .PARAMETER SMTPserver
            The server to use for sending the mail. 
        .NOTES
            TIP: Use a domain dfp-file to set default SMTP server name
    
            Send-MailMessage*:SMTPserver="smtp.contoso.com"
    
        #>
            Param(
         [parameter(mandatory=$true)]
         [string]$MailTo,
         [string]$MailFrom,
         [parameter(mandatory=$true)]
         [string]$Subject,
         [string]$TemplateFile,
          [parameter(mandatory=$true)]
         [hashtable]$replacementHash,
         [string[]]$Attachments,
         [string]$SMTPserver
        )
        
        if (Test-Path $TemplateFile) {        
            $messageBody = Get-Content -Path $TemplateFile | Out-String
    
            ForEach($key in $replacementHash.Keys) {
                $messageBody = $messageBody -replace $key,$replacementHash[$key]
            }
            Write-Verbose "Send mail to [$MailTo] from [$MailFrom] using [$SMTPserver]"
            Send-MailMessage -SmtpServer $SMTPserver -To $MailTo -From $MailFrom -Subject $Subject -Body $messageBody -BodyAsHtml -ErrorAction Stop -Encoding UTF8 -Attachments $Attachments
           
        } else {
            Msg "Missing mail template file $TemplateFile" "Warning"
        }
    }
    