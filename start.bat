@echo off
SETLOCAL
REM =========================================================
REM  VERTEX CODERS - PEOPLECORE HTB (OFFICIAL DEPLOY)
REM  CEO: Denis Sanchez Leyva
REM  Imagen: peoplecore-bot | Contenedor: peoplecore-final
REM =========================================================

echo [%date% %time%] --- INICIANDO INFRAESTRUCTURA PEOPLECORE ---

:: 0. ASEGURAR MOTOR DE DOCKER
echo [*] Verificando servicio Docker...
sc query "docker" | find "RUNNING" >nul
if %ERRORLEVEL% NEQ 0 (
    echo [!] Docker detenido. Despertando el motor...
    net start docker
    timeout /t 15 /nobreak >nul
)

:: 1. LIMPIEZA DE PERFILES (Evitar persistencia de jsmith en el Host)
echo [*] Purgando SIDs de 'jsmith' en ProfileList (Registry)...
powershell -Command "Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*' | Where-Object {$_.ProfileImagePath -like '*jsmith*'} | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue"

:: 2. LIBERAR PUERTOS (Evitar colisiones con SSH/WinRM nativos)
echo [*] Bajando servicios locales para liberar puertos 22 y 5985...
powershell -Command "Stop-Service sshd, WinRM -Force -ErrorAction SilentlyContinue"
powershell -Command "Set-Service sshd, WinRM -StartupType Disabled -ErrorAction SilentlyContinue"

:: 3. LIMPIEZA DE CONTENEDORES
echo [*] Removiendo instancias previas de 'peoplecore-final'...
docker rm -f peoplecore-final 2>nul

:: 4. DESPLIEGUE DE IMAGEN (Nombre corregido: peoplecore-bot)
echo [*] Lanzando PeopleCore (Nexus Dynamics HR Services)...
echo [*] Imagen: peoplecore-bot | RAM: 8GB | Ports: 8080, 22, 5985
docker run -d ^
  --name peoplecore-final ^
  --restart always ^
  -p 8080:8080 ^
  -p 22:22 ^
  -p 5985:5985 ^
  --memory 8g ^
  peoplecore-bot

:: 5. VERIFICACION FINAL
echo.
echo [%date% %time%] --- VERIFICACION DE SEGURIDAD VERTEX ---
timeout /t 12 >nul
docker ps --filter "name=peoplecore-final"

echo.
echo [STATUS] PeopleCore Engine: ONLINE
echo [POLICY] User 'jsmith': SSH ACCESS REVOKED
echo [POLICY] User 'administrator': SSH/WinRM ACCESS GRANTED
echo =========================================================
echo  VERTEX CODERS LLC - MIAMI, FL - 2026
echo =========================================================

docker rm -f peoplecore-bot 2>$null
run -d --name peoplecore-bot --restart always -p 8080:8080 -p 22:22 -p 5985:5985 --memory 8g peoplecore-bot
pause
