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
ENV PATH="C:\Python311;C:\Python311\Scripts;C:\OpenSSH;${PATH}"

WORKDIR C:/app

# ============================================
# 3. INSTALAR OPENSSH (VIA BINARIOS - EVITA ERROR 0x2)
# ============================================
# Descargamos el release oficial de GitHub para no depender de Add-WindowsCapability
ADD https://github.com/PowerShell/Win32-OpenSSH/releases/download/v9.5.0.0p1-Beta/OpenSSH-Win64.zip C:/openssh.zip
RUN Expand-Archive -Path C:/openssh.zip -DestinationPath C:/ ; \
    Move-Item -Path C:/OpenSSH-Win64 -Destination C:/OpenSSH ; \
    C:/OpenSSH/install-sshd.ps1 ; \
    Set-Service -Name sshd -StartupType 'Automatic' ; \
    # Configurar SSH
    (Get-Content C:\OpenSSH\sshd_config_default) -replace '#PasswordAuthentication yes', 'PasswordAuthentication yes' | Set-Content C:\OpenSSH\sshd_config

# ============================================
# 4. DEPENDENCIAS Y MODELO (IA)
# ============================================
RUN & C:\Python311\python.exe -m pip install --upgrade pip; \
    & C:\Python311\python.exe -m pip install --no-cache-dir -r requirements.txt

# Pre-descarga del modelo para que sea OFFLINE
RUN python -c "from transformers import AutoTokenizer, AutoModelForCausalLM; \
    AutoTokenizer.from_pretrained('Qwen/Qwen2.5-0.5B-Instruct'); \
    AutoModelForCausalLM.from_pretrained('Qwen/Qwen2.5-0.5B-Instruct')"

# ============================================
# 5. CÓDIGO Y CONFIGURACIÓN DE RED TEAMING
# ============================================
COPY . .

# Configuración de WinRM y Usuarios (Tu lógica de setup.ps1)
RUN powershell -ExecutionPolicy Bypass -File setup.ps1 ; \
    $password = ConvertTo-SecureString 'HR@Nexus2024!' -AsPlainText -Force; \
    New-LocalUser -Name 'hruser' -Password $password -FullName 'HR User'; \
    Add-LocalGroupMember -Group 'Administrators' -Member 'hruser' ; \
    # Flags HTB
    New-Item -ItemType Directory -Force -Path C:\Users\hruser; \
    "HTB{user_placeholder_md5}" | Out-File -FilePath C:\Users\hruser\user.txt -Encoding ascii; \
    "HTB{root_placeholder_md5}" | Out-File -FilePath C:\Users\Administrator\root.txt -Encoding ascii

# ============================================
# 6. PUERTOS Y ARRANQUE
# ============================================
EXPOSE 8080 22 445 5985

CMD Start-Service sshd; \
    Start-Service WinRM; \
    waitress-serve --port=8080 app:app
