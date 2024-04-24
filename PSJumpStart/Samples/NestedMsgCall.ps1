function FirstMsg($message) {
    #$PSDefaultParameterValues = (Get-Variable -Name PSDefaultParameterValues -Scope Global).Value
    Msg("level1" + $message)
    SecMsg $message
}
function SecMsg($message) {
    Msg("level2" + $message)
}