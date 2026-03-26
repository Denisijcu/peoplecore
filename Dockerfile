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

# 4. INSTALAR DEPENDENCIAS (USANDO RUTA ABSOLUTA)
RUN C:\Python311\python.exe -m pip install --upgrade pip
RUN C:\Python311\python.exe -m pip install --no-cache-dir -r requirements.txt

# 5. INSTALAR OPENSSH (VIA POWERSHELL CON RUTA ABSOLUTA)
ADD https://github.com/PowerShell/Win32-OpenSSH/releases/download/v9.5.0.0p1-Beta/OpenSSH-Win64.zip C:/openssh.zip
RUN powershell -Command "Expand-Archive -Path C:/openssh.zip -DestinationPath C:/ ; Move-Item -Path C:/OpenSSH-Win64 -Destination C:/OpenSSH"
RUN powershell -ExecutionPolicy Bypass -File C:/OpenSSH/install-sshd.ps1


# 6. MODELO IA Y CÓDIGO (FIXED: Import torch added)
RUN C:\Python311\python.exe -c "import torch; from transformers import AutoTokenizer, AutoModelForCausalLM; \
    AutoTokenizer.from_pretrained('Qwen/Qwen2.5-0.5B-Instruct', trust_remote_code=True); \
    AutoModelForCausalLM.from_pretrained('Qwen/Qwen2.5-0.5B-Instruct', torch_dtype=torch.float32, trust_remote_code=True).to('cpu')"

COPY . .

# 8. EL FALLO HUMANO (Pista de acceso para el jugador)
RUN powershell -Command " \
    $contenido = 'USUARIO: jsmith`nCLAVE: Welcome1!`nNOTA: James, no olvides cambiar esto.'; \
    Set-Content -Path C:\app\nota_jsmith.txt -Value $contenido -Encoding ascii"
# 7. USUARIOS Y FLAGS
RUN powershell -Command " \
    $pass = ConvertTo-SecureString 'Welcome1!' -AsPlainText -Force; \
    New-LocalUser -Name 'jsmith' -Password $pass -FullName 'HR User'; \
    Add-LocalGroupMember -Group 'Administrators' -Member 'hruser'; \
    New-Item -ItemType Directory -Force -Path C:\Users\hruser\Desktop; \
    New-Item -ItemType Directory -Force -Path C:\Users\Administrator\Desktop; \
    'HTB{user_md5_hash}' | Out-File -FilePath C:\Users\hruser\Desktop\user.txt -Encoding ascii; \
    'HTB{root_md5_hash}' | Out-File -FilePath C:\Users\Administrator\Desktop\root.txt -Encoding ascii"

# 8. CREAR SMB SHARE HR-Docs (SOLO AGREGAR ESTO)
# 8. PREPARAR CARPETA (Sin crear el share aquí porque el servicio está off)
#RUN powershell -Command " \
#    New-Item -ItemType Directory -Force -Path C:\HR-Docs; \
 #   if (Test-Path C:\app\smb\HR-Docs) { Copy-Item -Path C:\app\smb\HR-Docs\* -Destination C:\HR-Docs\ -Recurse -Force }"

EXPOSE 8080 22 445 5985

# FIX SMB: Forzar arranque del servicio Server en el registro
RUN reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer" /v Start /t REG_DWORD /d 2 /f
RUN reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer" /v Type /t REG_DWORD /d 32 /f
# 8. FIX SMB AGRESIVO (Borrar dependencias y forzar inicio)
RUN reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer" /v Start /t REG_DWORD /d 2 /f && \
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer" /v DependOnService /t REG_MULTI_SZ /d "" /f && \
    powershell -Command "New-Item -ItemType Directory -Force -Path C:\HR-Docs"



# 9. ARRANQUE (Activamos el servicio y el share al encender)
CMD powershell -Command " \
    Start-Service sshd; \
    Start-Service WinRM; \
    Write-Host 'Iniciando PeopleCore Services...'; \
    $networkTask = Start-Job -ScriptBlock { \
        C:\Python311\python.exe -c \"import socket; s=socket.socket(); s.bind(('0.0.0.0', 445)); s.listen(5); print('SMB Port 445 is now listening'); while True: conn, addr = s.accept(); conn.close()\" \
    }; \
    C:\Python311\Scripts\waitress-serve.exe --port=8080 app:app"
