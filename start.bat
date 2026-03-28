@echo off
SETLOCAL
REM =========================================================
REM  VERTEX CODERS - PEOPLECORE HTB AUTO-START (ADAPTADO)
REM  Proyecto: VIC / PeopleCore
REM  Escrito por: Denis Sanchez Leyva (CEO)
REM =========================================================

echo [%date% %time%] --- INICIANDO DESPLIEGUE VERTEX (NUEVO NOMBRE) ---

:: 1. Limpieza de perfiles huerfanos (Evita el error .BA612...)
echo [*] Limpiando residuos de perfiles en el registro...
powershell -Command "Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*' | Where-Object {$_.ProfileImagePath -like '*jsmith*'} | Remove-Item -Force -ErrorAction SilentlyContinue"

:: 2. Detener servicios que chocan con los puertos del contenedor
echo [*] Liberando puertos (SSH y WinRM)...
powershell -Command "Stop-Service sshd -ErrorAction SilentlyContinue"
powershell -Command "Stop-Service WinRM -ErrorAction SilentlyContinue"

:: 3. Limpiar contenedor anterior si existe (Usando el nuevo nombre)
echo [*] Removiendo instancias viejas de PeopleCore-Bot...
docker rm -f peoplecore-bot 2>nul

:: 4. Lanzar el contenedor con los puertos y recursos de Vertex
:: Nota: Mantenemos el tag peoplecore-bot que ya tienes buildeado
echo [*] Lanzando PeopleCore (Puertos: 8080, 22, 5985)...
echo [*] Memoria asignada: 8GB | Auto-restart: Always
docker run -d ^
  --name peoplecore-bot ^
  --restart always ^
  -p 8080:8080 ^
  -p 22:22 ^
  -p 5985:5985 ^
  --memory 8g ^
  peoplecore-bot

:: 5. Verificacion final
echo.
echo [%date% %time%] --- DESPLIEGUE COMPLETADO ---
echo Verificando logs del contenedor...
timeout /t 5 >nul
docker ps --filter "name=peoplecore-bot"

pause
