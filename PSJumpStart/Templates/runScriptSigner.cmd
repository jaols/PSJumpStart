@echo off
SetLocal
REM
REM This cmd file will launch it's corresponding PowerShell-script. 
REM All prameters will pass into the powershell.
REM
REM We need to change std character set to support international characters 
REM when calling a PowerShell script (it's ohh soo 2018).
REM
chcp 1252 > nul
Set MyName=%~n0

REM For date format yyyy-MM:
Set ErrLog="%~dp0logs\ERR_%MyName:~3%_%DATE:~0,7%.log"
Set StdLog="%~dp0logs\%MyName:~3%_%DATE:~0,7%.log"

REM For others
Set ErrLog="%~dp0logs\ERR_%MyName:~3%_%DATE:~0,7%.log"
Set StdLog="%~dp0logs\%MyName:~3%_%DATE:~0,7%.log"

REM This line will catch output to same file and folder
REM PowerShell -File "%~dp0%MyName:~3%.ps1" %* >> %StdLog% 2>&1

REM This line will launch with a separate ERROR-log
echo %DATE% %TIME% >> %StdLog%
PowerShell -NoProfile -ExecutionPolicy Bypass -File "%~dp0%MyName:~3%.ps1" %* >> %StdLog% 2> %ErrLog%
echo %DATE% %TIME% >> %StdLog%

REM Remove error log if empty
findstr "^" %ErrLog% || del %ErrLog% >nul 

REM Show output.
Type %StdLog%

chcp 850 > nul
EndLocal