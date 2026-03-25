# setup.ps1 — Para ejecutar DENTRO del contenedor
Write-Host "⚙️ Configurando PeopleCore environment..." -ForegroundColor Cyan

# Crear SMB Share con HR-Docs (dentro del contenedor)
$sharePath = "C:\smb\HR-Docs"
if (Test-Path $sharePath) {
    New-SmbShare -Name "HR-Docs" -Path $sharePath -ReadAccess "Everyone" -ErrorAction SilentlyContinue
    Write-Host "✅ SMB Share HR-Docs creado" -ForegroundColor Green
} else {
    Write-Host "⚠️ Ruta $sharePath no encontrada" -ForegroundColor Yellow
}

# Habilitar WinRM
Enable-PSRemoting -Force -SkipNetworkProfileCheck
Write-Host "✅ WinRM habilitado" -ForegroundColor Green

# Crear usuario hruser si no existe
$userExists = Get-LocalUser -Name "hruser" -ErrorAction SilentlyContinue
if (-not $userExists) {
    $password = ConvertTo-SecureString 'HR@Nexus2024!' -AsPlainText -Force
    New-LocalUser -Name "hruser" -Password $password -FullName "HR User" -Description "HR User Account"
    Add-LocalGroupMember -Group "Users" -Member "hruser"
    Write-Host "✅ Usuario hruser creado" -ForegroundColor Green
}

Write-Host "🎯 Setup completo!" -ForegroundColor Cyan