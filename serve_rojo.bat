@echo off
cd /d "%~dp0"
echo ========================================================
echo  DEMARRAGE DU SERVEUR DE SYNC ROJO (LIVE STUDIO SYNC)
echo ========================================================
npx --yes rojo serve
pause
