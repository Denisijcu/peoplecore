# ============================================
# VERTEX CODERS - PEOPLECORE HTB (FINAL)
# ============================================
FROM mcr.microsoft.com/windows/servercore:ltsc2022

# Shell con manejo de errores estricto
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# 1. PYTHON 3.11
ADD https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe C:/python-installer.exe
RUN Start-Process C:/python-installer.exe -ArgumentList '/quiet InstallAllUsers=1 PrependPath=1 TargetDir=C:\Python311' -Wait ; \
    Remove-Item C:/python-installer.exe

# 2. VC REDIST (Fix para WinError 126 en Torch)
ADD https://aka.ms/vs/17/release/vc_redist.x64.exe C:/vc_redist.x64.exe
RUN Start-Process C:/vc_redist.x64.exe -ArgumentList '/install /quiet /norestart' -Wait ; \
    Remove-Item C:/vc_redist.x64.exe# ============================================
# VERTEX CODERS - PEOPLECORE HTB (FINAL FIX)
# ============================================
FROM mcr.microsoft.com/windows/servercore:ltsc2022

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# 1. PYTHON 3.11
ADD https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe C:/python-installer.exe
RUN Start-Process C:/python-installer.exe -ArgumentList '/quiet InstallAllUsers=1 PrependPath=1 TargetDir=C:\Python311' -Wait ; \
    Remove-Item C:/python-installer.exe

# 2. VC REDIST (Fix WinError 126)
ADD https://aka.ms/vs/17/release/vc_redist.x64.exe C:/vc_redist.x64.exe
RUN Start-Process C:/vc_redist.x64.exe -ArgumentList '/install /quiet /norestart' -Wait ; \
    Remove-Item C:/vc_redist.x64.exe

# 3. ENTORNOS
ENV PATH="C:\Python311;C:\Python311\Scripts;C:\OpenSSH;${PATH}"
WORKDIR C:/app

# 4. OPENSSH - ELIMINACIÓN DEL ERROR 0x2
ADD https://github.com/PowerShell/Win32-OpenSSH/releases/download/v9.5.0.0p1-Beta/OpenSSH-Win64.zip C:/openssh.zip

# SEPARAMOS LOS RUNS PARA QUE EL SISTEMA DE ARCHIVOS SE ACTUALICE
RUN Expand-Archive -Path C:/openssh.zip -DestinationPath C:/
RUN $folder = Get-ChildItem -Path C:/ -Filter OpenSSH* -Directory | Select-Object -First 1 ; \
    Move-Item -Path $folder.FullName -Destination C:/OpenSSH ; \
    Remove-Item C:/openssh.zip

RUN powershell.exe -ExecutionPolicy Bypass -File C:/OpenSSH/install-sshd.ps1
RUN Set-Service -Name sshd -StartupType 'Automatic' ; \
    (Get-Content C:/OpenSSH/sshd_config_default) -replace '#PasswordAuthentication yes', 'PasswordAuthentication yes' | Set-Content C:/OpenSSH/sshd_config

# 5. DEPENDENCIAS
COPY requirements.txt .
RUN C:\Python311\python.exe -m pip install --upgrade pip ; \
    C:\Python311\python.exe -m pip install --no-cache-dir -r requirements.txt

# 6. MODELO IA
RUN C:\Python311\python.exe -c "from transformers import AutoTokenizer, AutoModelForCausalLM; \
    AutoTokenizer.from_pretrained('Qwen/Qwen2.5-0.5B-Instruct'); \
    AutoModelForCausalLM.from_pretrained('Qwen/Qwen2.5-0.5B-Instruct')"

# 7. CÓDIGO Y RED TEAMING
COPY . .
RUN powershell.exe -ExecutionPolicy Bypass -File ./setup.ps1

# 8. USUARIO Y FLAGS
RUN $password = ConvertTo-SecureString 'HR@Nexus2024!' -AsPlainText -Force; \
    if (-not (Get-LocalUser -Name 'hruser' -ErrorAction SilentlyContinue)) { \
        New-LocalUser -Name 'hruser' -Password $password -FullName 'HR User'; \
    }; \
    Add-LocalGroupMember -Group 'Administrators' -Member 'hruser'; \
    New-Item -ItemType Directory -Force -Path C:\Users\hruser; \
    'HTB{user_placeholder_md5}' | Out-File -FilePath C:\Users\hruser\user.txt -Encoding ascii; \
    'HTB{root_placeholder_md5}' | Out-File -FilePath C:\Users\Administrator\root.txt -Encoding ascii

EXPOSE 8080 22 445 5985

# 10. ARRANQUE
CMD Start-Service sshd; \
    Start-Service WinRM; \
    C:\Python311\Scripts\waitress-serve.exe --port=8080 app:app

# 3. ENTORNOS
ENV PATH="C:\Python311;C:\Python311\Scripts;C:\OpenSSH;${PATH}"
WORKDIR C:/app

# 4. OPENSSH - FIX DEFINITIVO ERROR 0x2
ADD https://github.com/PowerShell/Win32-OpenSSH/releases/download/v9.5.0.0p1-Beta/OpenSSH-Win64.zip C:/openssh.zip

# CAPA 10: Extracción y limpieza del zip
RUN Expand-Archive -Path C:/openssh.zip -DestinationPath C:/ ; Remove-Item C:/openssh.zip

# CAPA 11: Movimiento dinámico (Busca la carpeta extraída sin importar el nombre)
RUN $folder = Get-ChildItem -Path C:/ -Filter OpenSSH* -Directory | Select-Object -First 1 ; \
    Move-Item -Path $folder.FullName -Destination C:/OpenSSH

# CAPA 12: Instalación y Configuración
RUN powershell.exe -ExecutionPolicy Bypass -File C:/OpenSSH/install-sshd.ps1 ; \
    Set-Service -Name sshd -StartupType 'Automatic' ; \
    (Get-Content C:/OpenSSH/sshd_config_default) -replace '#PasswordAuthentication yes', 'PasswordAuthentication yes' | Set-Content C:/OpenSSH/sshd_config

# 5. DEPENDENCIAS (Uso de ruta absoluta)
COPY requirements.txt .
RUN C:\Python311\python.exe -m pip install --upgrade pip ; \
    C:\Python311\python.exe -m pip install --no-cache-dir -r requirements.txt

# 6. MODELO IA
RUN C:\Python311\python.exe -c "from transformers import AutoTokenizer, AutoModelForCausalLM; \
    AutoTokenizer.from_pretrained('Qwen/Qwen2.5-0.5B-Instruct'); \
    AutoModelForCausalLM.from_pretrained('Qwen/Qwen2.5-0.5B-Instruct')"

# 7. CÓDIGO Y RED TEAMING
COPY . .
RUN powershell.exe -ExecutionPolicy Bypass -File ./setup.ps1

# 8. USUARIO Y FLAGS
RUN $password = ConvertTo-SecureString 'HR@Nexus2024!' -AsPlainText -Force; \
    if (-not (Get-LocalUser -Name 'hruser' -ErrorAction SilentlyContinue)) { \
        New-LocalUser -Name 'hruser' -Password $password -FullName 'HR User'; \
    }; \
    Add-LocalGroupMember -Group 'Administrators' -Member 'hruser'; \
    New-Item -ItemType Directory -Force -Path C:\Users\hruser; \
    'HTB{user_placeholder_md5}' | Out-File -FilePath C:\Users\hruser\user.txt -Encoding ascii; \
    'HTB{root_placeholder_md5}' | Out-File -FilePath C:\Users\Administrator\root.txt -Encoding ascii

# 9. PUERTOS
EXPOSE 8080 22 445 5985

# 10. ARRANQUE
CMD Start-Service sshd; \
    Start-Service WinRM; \
    C:\Python311\Scripts\waitress-serve.exe --port=8080 app:app
