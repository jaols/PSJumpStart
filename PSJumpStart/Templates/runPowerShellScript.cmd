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

REM Get current time in variables (%Year%,%Month%,%Day%...and more)
for /f %%x in ('wmic path win32_localtime get /format:list ^| findstr "="') do set %%x

REM Set log file names
Set ErrLog="%~dp0logs\ERR_%MyName:~3%_%Year%-%Month%-%Day%.log"
Set StdLog="%~dp0logs\%MyName:~3%_%Year%-%Month%.log"

REM This line will catch output to same file and folder
REM PowerShell -File "%~dp0%MyName:~3%.ps1" %* >> %StdLog% 2>&1

REM This line will launch with a separate ERROR-log
PowerShell -Command "%~dp0%MyName:~3%.ps1" %* >> %StdLog% 2>> %ErrLog%

REM Remove error log if empty
findstr "^" %ErrLog% || del %ErrLog% >nul 

chcp 850 > nul
EndLocal