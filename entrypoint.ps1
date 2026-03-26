# 1. Levantar servicios esenciales
Write-Host "Levantando la casa..."
Start-Service sshd, WinRM, LanmanServer -ErrorAction SilentlyContinue

# 2. Configurar el SMB (Ahora sí va a funcionar porque el container está vivo)
if (-not (Get-SmbShare -Name "HR-Docs" -ErrorAction SilentlyContinue)) {
    New-SmbShare -Name "HR-Docs" -Path "C:\HR-Docs" -ReadAccess "Everyone" -FullAccess "Administrator"
}

# 3. Permisos de seguridad
icacls "C:\HR-Docs" /grant "Everyone:(OI)(CI)F" /T

# 4. Arrancar la IA (Waitress)
Write-Host "IA PeopleCore lista en el puerto 8080"
C:\Python311\python.exe -m waitress --port=8080 app:app
