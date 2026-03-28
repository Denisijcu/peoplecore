@echo off
SETLOCAL
REM =========================================================
REM  VERTEX CODERS - PEOPLECORE HTB (PRODUCTION DEPLOY)
REM  Escrito por: Denis Sanchez Leyva (CEO)
REM =========================================================

echo [%date% %time%] --- INICIANDO INFRAESTRUCTURA PEOPLECORE ---

:: 1. Limpieza de perfiles (Crucial para el usuario jsmith del Dockerfile)
echo [*] Limpiando residuos de ProfileList (Target: jsmith)...
powershell -Command "Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*' | Where-Object {$_.ProfileImagePath -like '*jsmith*'} | Remove-Item -Force -ErrorAction SilentlyContinue"
powershell -Command "Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*' | Where-Object {$_.ProfileImagePath -like '*jsmith*'} | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue"

:: 2. Liberar puertos del Host para que Docker los tome
echo [*] Deteniendo servicios locales (SSH/WinRM/Web) para evitar colisiones...
powershell -Command "Stop-Service sshd, WinRM -ErrorAction SilentlyContinue"

:: 3. Limpieza de contenedores anteriores
echo [*] Removiendo instancias previas de PeopleCore...
docker rm -f peoplecore-final 2>nul

:: 4. Lanzar el contenedor con la configuracion del Dockerfile
:: Exponemos 8080 (Web), 22 (SSH Admin) y 5985 (WinRM Admin)
echo [*] Lanzando PeopleCore (Nexus Dynamics HR Services)...
echo [*] Recursos: 8GB RAM | Modelo: Qwen2.5-0.5B
docker run -d ^
  --name peoplecore-final ^
  --restart always ^
  -p 8080:8080 ^
  -p 22:22 ^
  -p 5985:5985 ^
  --memory 8g ^
  peoplecore:final

:: 5. Verificacion de Seguridad Vertex
echo.
echo [%date% %time%] --- DESPLIEGUE VERTEX COMPLETADO ---
echo Verificando que el bot de IA y el Web Service esten ONLINE...
timeout /t 10 >nul
docker ps --filter "name=peoplecore-final"
echo.
echo [!] Recordatorio: jsmith no tiene acceso SSH (DenyUsers en Dockerfile)
echo [!] Credenciales: administrator / NexusAdmin2024!

pause
