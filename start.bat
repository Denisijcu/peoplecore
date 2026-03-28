@echo off
SETLOCAL
REM =========================================================
REM  VERTEX CODERS - PEOPLECORE HTB (OFFICIAL DEPLOY)
REM  CEO: Denis Sanchez Leyva
REM  Fix: Uniform naming to 'peoplecore-bot'
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

:: 1. LIMPIEZA DE PERFILES (jsmith)
echo [*] Purgando SIDs de 'jsmith' en el Registro...
powershell -Command "Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*' | Where-Object {$_.ProfileImagePath -like '*jsmith*'} | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue"

:: 2. LIBERAR PUERTOS
echo [*] Deteniendo SSH/WinRM locales para evitar colisiones...
powershell -Command "Stop-Service sshd, WinRM -Force -ErrorAction SilentlyContinue"

:: 3. LIMPIEZA DE CONTENEDORES (Usando el nombre correcto)
echo [*] Removiendo instancias previas de 'peoplecore-bot'...
docker rm -f peoplecore-bot 2>nul

:: 4. LANZAR CONTENEDOR (Nombre: peoplecore-bot | Imagen: peoplecore-bot)
echo [*] Lanzando PeopleCore (Nexus Dynamics HR Services)...
docker run -d ^
  --name peoplecore-bot ^
  --restart always ^
  -p 8080:8080 ^
  -p 22:22 ^
  -p 5985:5985 ^
  --memory 8g ^
  peoplecore-bot

:: 5. VERIFICACION
echo.
echo [%date% %time%] --- DESPLIEGUE VERTEX COMPLETADO ---
timeout /t 5 >nul
docker ps --filter "name=peoplecore-bot"
pause
