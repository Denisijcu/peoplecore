# ============================================
# VERTEX CODERS - PEOPLECORE HTB (FIX FINAL)
# ============================================
FROM mcr.microsoft.com/windows/servercore:ltsc2022

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# 1. PYTHON 3.11 Y VC REDIST (INSTALACIÓN DIRECTA)
ADD https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe C:/python-installer.exe
RUN Start-Process C:/python-installer.exe -ArgumentList '/quiet InstallAllUsers=1 PrependPath=1 TargetDir=C:\Python311' -Wait ; Remove-Item -Force C:/python-installer.exe

ADD https://aka.ms/vs/17/release/vc_redist.x64.exe C:/vc_redist.x64.exe
RUN Start-Process C:/vc_redist.x64.exe -ArgumentList '/install /quiet /norestart' -Wait ; Remove-Item -Force C:/vc_redist.x64.exe

ENV PATH="C:\Python311;C:\Python311\Scripts;C:\OpenSSH;${PATH}"
WORKDIR C:/app

# 2. OPENSSH - ESTA ES LA ÚNICA FORMA QUE NO DA ERROR 0x2
# En lugar de ADD y Expand-Archive que falla, bajamos el MSI oficial si estuviera, 
# pero como usamos el ZIP, lo hacemos en DOS RUNS SEPARADOS DE VERDAD.
ADD https://github.com/PowerShell/Win32-OpenSSH/releases/download/v9.5.0.0p1-Beta/OpenSSH-Win64.zip C:/openssh.zip

# RUN 1: SOLO EXTRAER
RUN Expand-Archive -Path C:/openssh.zip -DestinationPath C:/

# RUN 2: SOLO MOVER (Aquí es donde el 0x2 morirá porque la carpeta ya existe)
RUN Move-Item -Path C:/OpenSSH-Win64 -Destination C:/OpenSSH ; Remove-Item -Force C:/openssh.zip

# RUN 3: INSTALAR
RUN powershell.exe -ExecutionPolicy Bypass -File C:/OpenSSH/install-sshd.ps1 ; \
    Set-Service -Name sshd -StartupType 'Automatic'

# 3. DEPENDENCIAS Y MODELO
COPY requirements.txt .
RUN C:\Python311\python.exe -m pip install --upgrade pip ; \
    C:\Python311\python.exe -m pip install --no-cache-dir -r requirements.txt

RUN C:\Python311\python.exe -c "from transformers import AutoTokenizer, AutoModelForCausalLM; \
    AutoTokenizer.from_pretrained('Qwen/Qwen2.5-0.5B-Instruct'); \
    AutoModelForCausalLM.from_pretrained('Qwen/Qwen2.5-0.5B-Instruct')"

# 4. CÓDIGO Y FLAGS
COPY . .
RUN powershell.exe -ExecutionPolicy Bypass -File ./setup.ps1

RUN $password = ConvertTo-SecureString 'HR@Nexus2024!' -AsPlainText -Force; \
    New-LocalUser -Name 'hruser' -Password $password -FullName 'HR User'; \
    Add-LocalGroupMember -Group 'Administrators' -Member 'hruser'; \
    New-Item -ItemType Directory -Force -Path C:\Users\hruser; \
    'HTB{user_placeholder_md5}' | Out-File -FilePath C:\Users\hruser\user.txt -Encoding ascii; \
    'HTB{root_placeholder_md5}' | Out-File -FilePath C:\Users\Administrator\root.txt -Encoding ascii

EXPOSE 8080 22 445 5985

CMD Start-Service sshd ; Start-Service WinRM ; C:\Python311\Scripts\waitress-serve.exe --port=8080 app:app
