# Usar Windows Server Core 2022
FROM mcr.microsoft.com/windows/servercore:ltsc2022

# Instalar Python 3.11
ADD https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe /python-installer.exe
RUN C:\python-installer.exe /quiet InstallAllUsers=1 PrependPath=1 TargetDir=C:\Python311 && \
    del C:\python-installer.exe

# Configurar variables
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]
ENV PATH="C:\Python311;C:\Python311\Scripts;${PATH}"

WORKDIR C:/app

# Instalar WinRM (sin SSH)
RUN Enable-PSRemoting -Force -SkipNetworkProfileCheck; \
    Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*" -Force; \
    winrm set winrm/config/service/auth '@{Basic="true"}'; \
    winrm set winrm/config/service '@{AllowUnencrypted="true"}'; \
    winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="1024"}'

# Copiar requirements y instalar dependencias
COPY requirements.txt .
RUN python -m pip install --upgrade pip; \
    pip install --no-cache-dir -r requirements.txt

# Pre-descargar modelo
RUN python -c "from transformers import AutoTokenizer, AutoModelForCausalLM; \
    AutoTokenizer.from_pretrained('Qwen/Qwen2.5-0.5B-Instruct', trust_remote_code=True); \
    AutoModelForCausalLM.from_pretrained('Qwen/Qwen2.5-0.5B-Instruct', torch_dtype=torch.float32, trust_remote_code=True).to('cpu')"

# Copiar aplicación
COPY app.py .
COPY ai_engine.py .
COPY ps_bridge.py .
COPY templates/ ./templates/
COPY smb/ ./smb/

# Crear usuario y flags
RUN $password = ConvertTo-SecureString 'HR@Nexus2024!' -AsPlainText -Force; \
    if (-not (Get-LocalUser -Name 'hruser' -ErrorAction SilentlyContinue)) { \
        New-LocalUser -Name 'hruser' -Password $password -FullName 'HR User' -Description 'HR User Account' \
    }; \
    Add-LocalGroupMember -Group 'Users' -Member 'hruser'; \
    New-Item -ItemType Directory -Force -Path C:\Users\hruser; \
    New-Item -ItemType Directory -Force -Path C:\Users\Administrator; \
    "HTB{user_placeholder_md5}" | Out-File -FilePath C:\Users\hruser\user.txt -Encoding ascii; \
    "HTB{root_placeholder_md5}" | Out-File -FilePath C:\Users\Administrator\root.txt -Encoding ascii; \
    icacls C:\Users\hruser\user.txt /grant hruser:R

EXPOSE 8080 5985

CMD Start-Service WinRM; waitress-serve --port=8080 app:app
