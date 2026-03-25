# Usar Windows Server Core 2022 como base
FROM mcr.microsoft.com/windows/servercore:ltsc2022

# ============================================
# 1. INSTALAR PYTHON 3.11
# ============================================
ADD https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe /python-installer.exe
RUN C:\python-installer.exe /quiet InstallAllUsers=1 PrependPath=1 TargetDir=C:\Python311 && \
    del C:\python-installer.exe

# ============================================
# 2. CONFIGURAR SHELL Y VARIABLES DE ENTORNO
# ============================================
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]
ENV PATH="C:\Python311;C:\Python311\Scripts;${PATH}"

# ============================================
# 3. ESTABLECER DIRECTORIO DE TRABAJO
# ============================================
WORKDIR C:/app

# ============================================
# 4. INSTALAR OPENSSH SERVER Y WINRM
# ============================================
# Instalar OpenSSH Server y WinRM
# Instalar OpenSSH Server
# Instalar OpenSSH Server usando DISM (más estable)
RUN dism /online /Enable-Feature /FeatureName:OpenSSH.Server /All /NoRestart

# Configurar servicios SSH
RUN Set-Service -Name sshd -StartupType 'Automatic'; \
    Set-Service -Name ssh-agent -StartupType 'Automatic'

# Configurar sshd_config (crear si no existe)
RUN $configPath = 'C:\Windows\System32\OpenSSH\sshd_config'; \
    if (-not (Test-Path $configPath)) { New-Item -Path $configPath -ItemType File -Force }; \
    (Get-Content $configPath) -replace '#PasswordAuthentication yes', 'PasswordAuthentication yes' | Set-Content $configPath; \
    (Get-Content $configPath) -replace '#PermitEmptyPassword no', 'PermitEmptyPassword no' | Set-Content $configPath

# Habilitar WinRM
RUN Enable-PSRemoting -Force -SkipNetworkProfileCheck; \
    Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*" -Force; \
    winrm set winrm/config/service/auth '@{Basic="true"}'; \
    winrm set winrm/config/service '@{AllowUnencrypted="true"}'
# ============================================
# 5. COPIAR REQUIREMENTS.TXT E INSTALAR DEPENDENCIAS PYTHON
# ============================================
COPY requirements.txt .
RUN python -m pip install --upgrade pip; \
    pip install --no-cache-dir -r requirements.txt

# ============================================
# 6. PRE-DESCARGAR MODELO QWEN (en tiempo de build)
# ============================================
RUN python -c "from transformers import AutoTokenizer, AutoModelForCausalLM; \
    AutoTokenizer.from_pretrained('Qwen/Qwen2.5-0.5B-Instruct'); \
    AutoModelForCausalLM.from_pretrained('Qwen/Qwen2.5-0.5B-Instruct')"

# ============================================
# 7. COPIAR TODO EL CÓDIGO DE LA APLICACIÓN
# ============================================
COPY app.py .
COPY ai_engine.py .
COPY ps_bridge.py .
COPY templates/ ./templates/
COPY static/ ./static/
COPY smb/ ./smb/

# ============================================
# 8. COPIAR SCRIPTS DE CONFIGURACIÓN
# ============================================
COPY setup.ps1 .
COPY generate_pdf.py .

# ============================================
# 9. EJECUTAR SETUP.PS1 (configura SMB y WinRM)
# ============================================
RUN powershell -ExecutionPolicy Bypass -File setup.ps1

# ============================================
# 10. CREAR USUARIO HRUSER Y FLAGS
# ============================================
RUN $password = ConvertTo-SecureString 'HR@Nexus2024!' -AsPlainText -Force; \
    # Crear usuario si no existe
    if (-not (Get-LocalUser -Name 'hruser' -ErrorAction SilentlyContinue)) { \
        New-LocalUser -Name 'hruser' -Password $password -FullName 'HR User' -Description 'HR User Account'; \
    }; \
    Add-LocalGroupMember -Group 'Users' -Member 'hruser'; \
    Add-LocalGroupMember -Group 'Administrators' -Member 'hruser'; \
    # Crear directorios home
    New-Item -ItemType Directory -Force -Path C:\Users\hruser; \
    New-Item -ItemType Directory -Force -Path C:\Users\Administrator; \
    # Crear flags en formato HTB
    "HTB{user_placeholder_md5}" | Out-File -FilePath C:\Users\hruser\user.txt -Encoding ascii; \
    "HTB{root_placeholder_md5}" | Out-File -FilePath C:\Users\Administrator\root.txt -Encoding ascii; \
    # Permisos: solo hruser puede leer su flag
    icacls C:\Users\hruser\user.txt /grant hruser:R; \
    # Root flag solo accesible por Administradores
    icacls C:\Users\Administrator\root.txt /grant Administrators:F

# ============================================
# 11. EXPONER PUERTOS
# ============================================
EXPOSE 8080 22 445 5985

# ============================================
# 12. COMANDO DE INICIO (SSH, WinRM y la app Flask con waitress)
# ============================================
CMD Start-Service sshd; \
    Start-Service WinRM; \
    Write-Host "🚀 PeopleCore iniciado en http://0.0.0.0:8080" -ForegroundColor Cyan; \
    Write-Host "📁 SMB share: \\localhost\HR-Docs" -ForegroundColor Cyan; \
    Write-Host "🔌 WinRM: port 5985" -ForegroundColor Cyan; \
    Write-Host "🔑 SSH: port 22" -ForegroundColor Cyan; \
    waitress-serve --port=8080 app:app
