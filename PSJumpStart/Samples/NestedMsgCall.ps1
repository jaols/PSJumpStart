function FirstMsg($message) {
    #$PSDefaultParameterValues = (Get-Variable -Name PSDefaultParameterValues -Scope Global).Value
    Write-Message ("level1" + $message)
    SecMsg $message
}
function SecMsg($message) {
    Write-Message ("level2" + $message)
}