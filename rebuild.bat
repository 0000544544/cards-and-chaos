@echo off
cd /d "%~dp0"
echo ========================================================
echo  COMPILATION DU PROJET STOP AT THE FRAME (.rbxl et .rbxlx)
echo ========================================================
call npx --yes rojo build -o StopAtTheFrame.rbxl
call npx --yes rojo build -o StopAtTheFrame.rbxlx
copy /Y "StopAtTheFrame.rbxl" "..\StopAtTheFrame.rbxl" >nul
copy /Y "StopAtTheFrame.rbxlx" "..\StopAtTheFrame.rbxlx" >nul
echo ========================================================
echo  Compilation terminee avec succes ! Fichiers a jour.
echo ========================================================
if "%1"=="" (
    rem Only pause if double-clicked in Explorer
    echo %cmdcmdline% | findstr /i /c:"%~nx0" >nul && pause
)
