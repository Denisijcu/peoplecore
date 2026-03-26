# ============================================
# VERTEX CODERS - PEOPLECORE HTB (FIX TOTAL)
# ============================================
FROM mcr.microsoft.com/windows/servercore:ltsc2022

# 1. INSTALACIÓN DE PYTHON (Ruta fija C:\Python311)
ADD https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe C:/python-installer.exe
RUN C:\python-installer.exe /quiet InstallAllUsers=1 PrependPath=1 TargetDir=C:\Python311
RUN del C:\python-installer.exe

# 2. VC REDIST (Fix WinError 126)
ADD https://aka.ms/vs/17/release/vc_redist.x64.exe C:/vc_redist.x64.exe
RUN C:\vc_redist.x64.exe /install /quiet /norestart
RUN del C:\vc_redist.x64.exe

# 3. CONFIGURACIÓN DE TRABAJO
WORKDIR C:/app
COPY requirements.txt .

# 4. INSTALAR DEPENDENCIAS (USANDO RUTA ABSOLUTA - MATA EL ERROR 0x2)
# Aquí es donde fallaba: llamamos al exe directamente
RUN C:\Python311\python.exe -m pip install --upgrade pip
RUN C:\Python311\python.exe -m pip install --no-cache-dir -r requirements.txt

# 5. INSTALAR OPENSSH (VIA POWERSHELL CON RUTA ABSOLUTA)
ADD https://github.com/PowerShell/Win32-OpenSSH/releases/download/v9.5.0.0p1-Beta/OpenSSH-Win64.zip C:/openssh.zip
RUN powershell -Command "Expand-Archive -Path C:/openssh.zip -DestinationPath C:/ ; Move-Item -Path C:/OpenSSH-Win64 -Destination C:/OpenSSH"
RUN powershell -ExecutionPolicy Bypass -File C:/OpenSSH/install-sshd.ps1

# 6. MODELO IA Y CÓDIGO
RUN C:\Python311\python.exe -c "from transformers import AutoTokenizer, AutoModelForCausalLM; \
    AutoTokenizer.from_pretrained('Qwen/Qwen2.5-0.5B-Instruct'); \
    AutoModelForCausalLM.from_pretrained('Qwen/Qwen2.5-0.5B-Instruct')"

COPY . .

# 7. USUARIOS Y FLAGS (ESTÁNDAR DENIS/HTB)
RUN powershell -Command " \
    $pass = ConvertTo-SecureString 'HR@Nexus2024!' -AsPlainText -Force; \
    New-LocalUser -Name 'hruser' -Password $pass -FullName 'HR User'; \
    Add-LocalGroupMember -Group 'Administrators' -Member 'hruser'; \
    # CREAR CARPETAS DE ESCRITORIO EXPLÍCITAMENTE \
    New-Item -ItemType Directory -Force -Path C:\Users\hruser\Desktop; \
    New-Item -ItemType Directory -Force -Path C:\Users\Administrator\Desktop; \
    # TIRAR LAS FLAGS DONDE VAN \
    'HTB{user_md5_hash}' | Out-File -FilePath C:\Users\hruser\Desktop\user.txt -Encoding ascii; \
    'HTB{root_md5_hash}' | Out-File -FilePath C:\Users\Administrator\Desktop\root.txt -Encoding ascii"

# Crear carpeta para HR-Docs y copiar el PDF
RUN New-Item -ItemType Directory -Force -Path C:\HR-Docs; \
    Copy-Item -Path C:\app\smb\HR-Docs\* -Destination C:\HR-Docs\ -Recurse -Force; \
    New-SmbShare -Name "HR-Docs" -Path "C:\HR-Docs" -ReadAccess "Everyone"
    


EXPOSE 8080 22 445 5985

# ARRANQUE
CMD powershell -Command "Start-Service sshd; Start-Service WinRM; C:\Python311\Scripts\waitress-serve.exe --port=8080 app:app"
