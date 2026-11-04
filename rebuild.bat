@echo off
cd /d "%~dp0"
echo ========================================================
echo  COMPILATION DU MONDE 3D ET DU CODE ROBLOX (.rbxl & .rbxlx)
echo ========================================================
call python generate_project.py
call npx --yes rojo build -o SovereignDominion.rbxl
call npx --yes rojo build -o SovereignDominion.rbxlx
echo ========================================================
echo  Compilation terminee avec succes !
echo ========================================================
pause
