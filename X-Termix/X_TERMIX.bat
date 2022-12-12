@echo off
echo @wrapper INFO: Windows BATCH spusten.
powershell -ExecutionPolicy Bypass -Command "Write-Host `@wrapper INFO: PowerShell spusten, nyni se nacte a spusti pozadovany skript.; & '%~d0%~p0%~n0.ps1'"
echo:
echo - - - - - - - - - - - - - - - - - - -
echo PowerShell exited with error level: %ERRORLEVEL%
echo - - - - - - - - - - - - - - - - - - -
echo:

if %ERRORLEVEL% NEQ 0 title %~n0 ^> EMERGENCY STOP / FAILURE & pause
exit /B %ERRORLEVEL%