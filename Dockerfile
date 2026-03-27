# ============================================
# VERTEX CODERS - PEOPLECORE HTB
# ============================================
FROM mcr.microsoft.com/windows/servercore:ltsc2022

# ── 1. PYTHON 3.11 ──────────────────────────────────────────
ADD https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe C:/python-installer.exe
RUN C:\python-installer.exe /quiet InstallAllUsers=1 PrependPath=1 TargetDir=C:\Python311
RUN del C:\python-installer.exe

# ── 2. VC REDIST ────────────────────────────────────────────
ADD https://aka.ms/vs/17/release/vc_redist.x64.exe C:/vc_redist.x64.exe
RUN C:\vc_redist.x64.exe /install /quiet /norestart
RUN del C:\vc_redist.x64.exe

# ── 3. DEPENDENCIAS PYTHON ──────────────────────────────────
WORKDIR C:/app
COPY requirements.txt .
RUN C:\Python311\python.exe -m pip install --upgrade pip
RUN C:\Python311\python.exe -m pip install --no-cache-dir -r requirements.txt

# ── 4. OPENSSH ──────────────────────────────────────────────
ADD https://github.com/PowerShell/Win32-OpenSSH/releases/download/v9.5.0.0p1-Beta/OpenSSH-Win64.zip C:/openssh.zip
RUN powershell -Command "Expand-Archive -Path C:/openssh.zip -DestinationPath C:/ ; Move-Item -Path C:/OpenSSH-Win64 -Destination C:/OpenSSH"
RUN powershell -ExecutionPolicy Bypass -File C:/OpenSSH/install-sshd.ps1

# ── 5. PRECARGAR MODELO IA ──────────────────────────────────
RUN C:\Python311\python.exe -c "import torch; from transformers import AutoTokenizer, AutoModelForCausalLM; \
    AutoTokenizer.from_pretrained('Qwen/Qwen2.5-0.5B-Instruct', trust_remote_code=True); \
    AutoModelForCausalLM.from_pretrained('Qwen/Qwen2.5-0.5B-Instruct', torch_dtype=torch.float32, trust_remote_code=True).to('cpu')"

# ── 6. COPIAR CÓDIGO ─────────────────────────────────────────
COPY . .

# ── 7. USUARIOS Y FLAGS (Arreglado) ──────────────────────────
RUN powershell -Command " \
    # 1. Configurar Administrator \
    net user Administrator 'NexusAdmin2024!' /active:yes; \
    \
    # 2. Configurar jsmith \
    $pass = ConvertTo-SecureString 'Welcome1!' -AsPlainText -Force; \
    New-LocalUser -Name 'jsmith' -Password $pass -FullName 'James Smith - HR Junior'; \
    Add-LocalGroupMember -Group 'Users' -Member 'jsmith'; \
    \
    # 3. Crear Directorios \
    New-Item -ItemType Directory -Force -Path C:\Users\jsmith\Desktop; \
    New-Item -ItemType Directory -Force -Path C:\Users\Administrator\Desktop; \
    New-Item -ItemType Directory -Force -Path C:\HR-Docs; \
    \
    # 4. Plantar Flags (MD5 Standard) \
    'HTB{6e8979e2c40c117d84878a8790325f6e}' | Out-File -FilePath C:\Users\jsmith\Desktop\user.txt -Encoding ascii; \
    'HTB{bfd7a04918e77c475d9e52c6f1082c5b}' | Out-File -FilePath C:\Users\Administrator\Desktop\root.txt -Encoding ascii"

# Crear policy.txt
# Crear policy.txt (Fix: No characters allowed after here-string header)
RUN powershell -Command " \
    $policy = @( \
        'NEXUS DYNAMICS CORP — EMPLOYEE HANDBOOK', \
        '========================================', \
        'Version: 4.2 | Classification: Internal', \
        '', \
        '1. DEFAULT CREDENTIALS:', \
        '- Portal: jsmith / Welcome1!', \
        '- Admin:  admin  / NexusAdmin2024!', \
        '', \
        'CONFIDENTIALITY NOTICE:', \
        'Unauthorized distribution is prohibited.' \
    ) -join [Environment]::NewLine; \
    $policy | Out-File -FilePath C:\HR-Docs\policy.txt -Encoding ascii"

# Permisos SSH
RUN net localgroup "Remote Management Users" Administrator /add

# ── 8. FALLO HUMANO ──────────────────────────────────────────
RUN powershell -Command " \
    New-Item -ItemType Directory -Force -Path C:\app\static; \
    'USUARIO: jsmith' | Out-File -FilePath C:\app\static\todo.txt -Encoding ascii; \
    'CLAVE: Welcome1!' | Out-File -FilePath C:\app\static\todo.txt -Append -Encoding ascii"

# ── 9. GODPOTATO (Asegúrate de tener la carpeta tools o comenta esta línea) ──
RUN powershell -Command "New-Item -ItemType Directory -Force -Path C:\Tools"
# COPY tools/GodPotato.exe C:/Tools/GodPotato.exe

# ── 10. PUERTOS ──────────────────────────────────────────────
EXPOSE 8080 22

# ── 11. ARRANQUE (Blindado) ──────────────────────────────────
CMD powershell -Command " \
    # Configurar SSH — Forzar clave y puerto \
    Start-Service sshd; \
    \
    # Configurar WinRM \
    Start-Service WinRM; \
    Set-Item WSMan:\localhost\Service\Auth\Basic -Value $true -Force; \
    Set-Item WSMan:\localhost\Service\AllowUnencrypted -Value $true -Force; \
    Set-Item WSMan:\localhost\Client\TrustedHosts -Value '*' -Force; \
    \
    Write-Host '[PeopleCore] Nexus Dynamics HR Services are ONLINE' -ForegroundColor Cyan; \
    C:\Python311\Scripts\waitress-serve.exe --port=8080 app:app"
