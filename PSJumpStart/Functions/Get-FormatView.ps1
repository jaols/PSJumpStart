#display a listing of all defined formatting views

Function Get-FormatView {
    [cmdletbinding()]
    [alias("gfv")]
    [OutputType("PSFormatView")]
    Param(
        [Parameter(HelpMessage = "Specify a typename such as System.Diagnostics.Process.",ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string]$TypeName = "*",
        [Parameter(HelpMessage = "Specify the version of PowerShell this cmdlet uses for the formatting data. Enter a two digit number separated by a period.")]
        [system.version]$PowerShellVersion = $PSVersionTable.PSVersion
    )
    Begin {
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Starting $($MyInvocation.MyCommand)"
        #a regular expression pattern to match on the format type
        [regex]$rx = "Table|List|Wide|Custom"
    } #begin

    Process {
        Try {
            $data = Get-FormatData -Typename $Typename -PowerShellVersion $PowerShellVersion -errorAction Stop | Sort-Object -Property TypeName
        }
        Catch {
            Throw $_
        }
        if ($data) {
            Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Found $($data.count) type definitions"
            #$data | Out-String | Write-Verbose
            foreach ($item in $data) {
                #there might be a collection of TypeNames
                foreach ($tn in $item.TypeNames) {
                    #$tn | out-string | write-verbose

                    Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Getting formatting view for $($tn)"
                    foreach ($view in $item.FormatViewDefinition) {
                        [PSCustomObject]@{
                            PSTypename = "PSFormatView"
                            Format = $rx.Match($view.Control).value
                            Name = $view.name
                            Typename = $tn
                            Control = $view.Control
                        }
                    }
                } #foreach tn
            } #foreach item
        } #if data

    } #process

    End {
        Write-Verbose "[$((Get-Date).TimeOfDay) END    ] Ending $($MyInvocation.MyCommand)"
    } #end

} #close Get-FormatView