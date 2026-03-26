# ============================================
# VERTEX CODERS - PEOPLECORE HTB (FIX TOTAL)
# ============================================
FROM mcr.microsoft.com/windows/servercore:ltsc2022

# 1. INSTALACIÓN DE PYTHON
ADD https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe C:/python-installer.exe
RUN C:\python-installer.exe /quiet InstallAllUsers=1 PrependPath=1 TargetDir=C:\Python311
RUN del C:\python-installer.exe

# 2. VC REDIST
ADD https://aka.ms/vs/17/release/vc_redist.x64.exe C:/vc_redist.x64.exe
RUN C:\vc_redist.x64.exe /install /quiet /norestart
RUN del C:\vc_redist.x64.exe

# 3. CONFIGURACIÓN
WORKDIR C:/app
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop';"]

# 4. DEPENDENCIAS PYTHON
COPY requirements.txt .
RUN C:\Python311\python.exe -m pip install --upgrade pip
RUN C:\Python311\python.exe -m pip install --no-cache-dir -r requirements.txt

# 5. OPENSSH
ADD https://github.com/PowerShell/Win32-OpenSSH/releases/download/v9.5.0.0p1-Beta/OpenSSH-Win64.zip C:/openssh.zip
RUN Expand-Archive -Path C:/openssh.zip -DestinationPath C:/ ; \
    Move-Item -Path C:/OpenSSH-Win64 -Destination C:/OpenSSH; \
    & C:/OpenSSH/install-sshd.ps1

# 6. MODELO IA
RUN C:\Python311\python.exe -c "from transformers import AutoTokenizer, AutoModelForCausalLM; \
    AutoTokenizer.from_pretrained('Qwen/Qwen2.5-0.5B-Instruct', trust_remote_code=True); \
    AutoModelForCausalLM.from_pretrained('Qwen/Qwen2.5-0.5B-Instruct', torch_dtype=torch.float32, trust_remote_code=True).to('cpu')"

# 7. COPIAR CÓDIGO FUENTE
COPY app.py .
COPY ai_engine.py .
COPY ps_bridge.py .
COPY templates/ ./templates/
COPY smb/ ./smb/

# 8. CREAR USUARIO Y FLAGS
RUN $pass = ConvertTo-SecureString 'HR@Nexus2024!' -AsPlainText -Force; \
    New-LocalUser -Name 'hruser' -Password $pass -FullName 'HR User'; \
    Add-LocalGroupMember -Group 'Administrators' -Member 'hruser'; \
    New-Item -ItemType Directory -Force -Path C:\Users\hruser\Desktop; \
    New-Item -ItemType Directory -Force -Path C:\Users\Administrator\Desktop; \
    'HTB{user_md5_hash}' | Out-File -FilePath C:\Users\hruser\Desktop\user.txt -Encoding ascii; \
    'HTB{root_md5_hash}' | Out-File -FilePath C:\Users\Administrator\Desktop\root.txt -Encoding ascii

# 9. CREAR SMB SHARE HR-Docs (¡LA PARTE CRÍTICA!)
RUN New-Item -ItemType Directory -Force -Path C:\smb\HR-Docs; \
    Copy-Item -Path C:\app\smb\HR-Docs\* -Destination C:\smb\HR-Docs\ -Recurse -Force; \
    New-SmbShare -Name "HR-Docs" -Path "C:\smb\HR-Docs" -ReadAccess "Everyone"

# 10. EXPONER PUERTOS
EXPOSE 8080 22 445 5985

# 11. ARRANQUE
CMD powershell -Command " \
    Start-Service sshd; \
    Start-Service WinRM; \
    C:\Python311\Scripts\waitress-serve.exe --port=8080 app:app"
