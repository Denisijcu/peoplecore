# ============================================
# VERTEX CODERS - PEOPLECORE HTB
# ============================================
FROM mcr.microsoft.com/windows/servercore:ltsc2022

# Configurar PowerShell como Shell por defecto
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# 1. INSTALAR PYTHON 3.11
ADD https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe C:/python-installer.exe
RUN Start-Process C:/python-installer.exe -ArgumentList '/quiet InstallAllUsers=1 PrependPath=1 TargetDir=C:\Python311' -Wait ; \
    Remove-Item C:/python-installer.exe

# 2. INSTALAR VC REDIST (Para evitar el WinError 126 en Torch)
ADD https://aka.ms/vs/17/release/vc_redist.x64.exe C:/vc_redist.x64.exe
RUN Start-Process C:/vc_redist.x64.exe -ArgumentList '/install /quiet /norestart' -Wait ; \
    Remove-Item C:/vc_redist.x64.exe

# 3. VARIABLES DE ENTORNO
ENV PATH="C:\Python311;C:\Python311\Scripts;C:\OpenSSH;${PATH}"
WORKDIR C:/app

# 4. INSTALAR OPENSSH (FIX ERROR 0x2)
# Usamos ADD para que lo baje solo y no dependa de archivos locales
ADD https://github.com/PowerShell/Win32-OpenSSH/releases/download/v9.5.0.0p1-Beta/OpenSSH-Win64.zip C:/openssh.zip

RUN Expand-Archive -Path C:/openssh.zip -DestinationPath C:/ ; \
    $folder = Get-ChildItem -Path C:/ -Filter OpenSSH* -Directory | Select-Object -First 1 ; \
    Move-Item -Path $folder.FullName -Destination C:/OpenSSH

RUN powershell.exe -ExecutionPolicy Bypass -File C:/OpenSSH/install-sshd.ps1

RUN Set-Service -Name sshd -StartupType 'Automatic' ; \
    (Get-Content C:/OpenSSH/sshd_config_default) -replace '#PasswordAuthentication yes', 'PasswordAuthentication yes' | Set-Content C:/OpenSSH/sshd_config

# 5. INSTALAR DEPENDENCIAS (Ruta absoluta para evitar fallos de PATH)
COPY requirements.txt .
RUN C:\Python311\python.exe -m pip install --upgrade pip ; \
    C:\Python311\python.exe -m pip install --no-cache-dir -r requirements.txt

# 6. DESCARGAR MODELO IA (Para que sea Offline en HTB)
RUN C:\Python311\python.exe -c "from transformers import AutoTokenizer, AutoModelForCausalLM; \
    AutoTokenizer.from_pretrained('Qwen/Qwen2.5-0.5B-Instruct'); \
    AutoModelForCausalLM.from_pretrained('Qwen/Qwen2.5-0.5B-Instruct')"

# 7. COPIAR CÓDIGO Y CONFIGURAR RED TEAMING
COPY . .
RUN powershell.exe -ExecutionPolicy Bypass -File ./setup.ps1

# 8. USUARIO Y FLAGS
RUN $password = ConvertTo-SecureString 'HR@Nexus2024!' -AsPlainText -Force; \
    New-LocalUser -Name 'hruser' -Password $password -FullName 'HR User'; \
    Add-LocalGroupMember -Group 'Administrators' -Member 'hruser'; \
    'HTB{user_placeholder_md5}' | Out-File -FilePath C:\Users\hruser\user.txt -Encoding ascii; \
    'HTB{root_placeholder_md5}' | Out-File -FilePath C:\Users\Administrator\root.txt -Encoding ascii

# 9. PUERTOS Y ARRANQUE
EXPOSE 8080 22 445 5985

CMD Start-Service sshd; \
    Start-Service WinRM; \
    C:\Python311\Scripts\waitress-serve.exe --port=8080 app:app
