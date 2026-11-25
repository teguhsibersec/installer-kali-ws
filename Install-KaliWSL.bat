@echo off
title teguhsibersec - Kali Linux WSL2 Installer
color 0B
mode con: cols=90 lines=40
echo.
echo   teguhsibersec :: Kali Linux WSL2 Installer
echo   Opsi lanjutan: Install-KaliWSL.bat -Tools default -Gui
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-KaliWSL.ps1" %*
pause
