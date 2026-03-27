# ============================================
# VERTEX CODERS - PEOPLECORE HTB
# Machine: PeopleCore (Medium - Windows)
# Attack Chain:
#   feroxbuster → /static/todo.txt → jsmith creds
#   → Login web → Prompt Injection IA → user.txt
#   → RCE via IA → GodPotato → SYSTEM
#   → SSH Administrator → root.txt
# ============================================
FROM mcr.microsoft.com/windows/servercore:ltsc2022

# ── 1. PYTHON 3.11 ──────────────────────────────────────────
ADD https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe C:/python-installer.exe
RUN C:\python-installer.exe /quiet InstallAllUsers=1 PrependPath=1 TargetDir=C:\Python311
RUN del C:\python-installer.exe

# ── 2. VC REDIST (Fix WinError 126) ─────────────────────────
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

# ── 5. CONFIGURAR SSH — SOLO ADMINISTRATOR ──────────────────
# jsmith NO tiene SSH. El jugador llega a Administrator
# únicamente via RCE (prompt injection) + privesc (GodPotato)
RUN powershell -Command " \
    $config = 'C:\OpenSSH\sshd_config'; \
    Add-Content -Path $config -Value ''; \
    Add-Content -Path $config -Value '# HTB: Solo Administrator puede usar SSH'; \
    Add-Content -Path $config -Value 'AllowUsers Administrator'; \
    Add-Content -Path $config -Value 'DenyUsers jsmith'; \
    Write-Host '[SSH] Restricted to Administrator only'"

# ── 6. PRECARGAR MODELO IA ──────────────────────────────────
RUN C:\Python311\python.exe -c "import torch; from transformers import AutoTokenizer, AutoModelForCausalLM; \
    AutoTokenizer.from_pretrained('Qwen/Qwen2.5-0.5B-Instruct', trust_remote_code=True); \
    AutoModelForCausalLM.from_pretrained('Qwen/Qwen2.5-0.5B-Instruct', torch_dtype=torch.float32, trust_remote_code=True).to('cpu')"

# ── 7. COPIAR CÓDIGO ─────────────────────────────────────────
COPY . .

# ── 8. USUARIOS Y FLAGS ──────────────────────────────────────
RUN powershell -Command " \
    $pass = ConvertTo-SecureString 'Welcome1!' -AsPlainText -Force; \
    New-LocalUser -Name 'jsmith' -Password $pass -FullName 'James Smith - HR Junior'; \
    Add-LocalGroupMember -Group 'Users' -Member 'jsmith'; \
    New-Item -ItemType Directory -Force -Path C:\Users\jsmith\Desktop; \
    New-Item -ItemType Directory -Force -Path C:\Users\Administrator\Desktop; \
    New-Item -ItemType Directory -Force -Path C:\HR-Docs; \
    'HTB{6e8979e2c40c117d84878a8790325f6e}' | Out-File -FilePath C:\Users\jsmith\Desktop\user.txt -Encoding ascii; \
    'HTB{bfd7a04918e77c475d9e52c6f1082c5b}' | Out-File -FilePath C:\Users\Administrator\Desktop\root.txt -Encoding ascii; \
    'Nexus Dynamics Internal Policy v1.0' | Out-File -FilePath C:\HR-Docs\policy.txt -Encoding ascii"

# ── 9. FALLO HUMANO (vector inicial) ─────────────────────────
RUN powershell -Command " \
    New-Item -ItemType Directory -Force -Path C:\app\static; \
    'USUARIO: jsmith'                    | Out-File -FilePath C:\app\static\todo.txt -Encoding ascii; \
    'CLAVE: Welcome1!'                   | Out-File -FilePath C:\app\static\todo.txt -Append -Encoding ascii; \
    'NOTA: James, no olvides cambiar esto.' | Out-File -FilePath C:\app\static\todo.txt -Append -Encoding ascii"

# ── 10. GODPOTATO — Herramienta de privesc preinstalada ──────
# El jugador la descubre via RCE y la usa para escalar a SYSTEM
# Ruta intencionalmente "olvidada" por el sysadmin en C:\Tools
RUN powershell -Command " \
    New-Item -ItemType Directory -Force -Path C:\Tools; \
    Write-Host '[Tools] C:\Tools ready for GodPotato'"
# NOTA: Agrega GodPotato.exe a tu carpeta local antes del build
# COPY tools/GodPotato.exe C:/Tools/GodPotato.exe

# ── 11. LIMPIAR SMB (no funciona en containers, quitar ruido) ─
# Se elimina el fake SMB — puerto 445 descartado del scope
# El Nmap solo mostrará: 8080 (HTTP) y 22 (SSH)

# ── 12. PUERTOS ──────────────────────────────────────────────
EXPOSE 8080 22

# ── 13. ARRANQUE ─────────────────────────────────────────────
CMD powershell -Command " \
    \
    # SSH — Reiniciar con config actualizada (AllowUsers Administrator) \
    Restart-Service sshd -Force; \
    Write-Host '[SSH] Started - Administrator only'; \
    \
    # WinRM — Para Evil-WinRM si el jugador llega a Administrator \
    Start-Service WinRM; \
    Set-Item WSMan:\localhost\Service\Auth\Basic        -Value $true -Force; \
    Set-Item WSMan:\localhost\Service\AllowUnencrypted  -Value $true -Force; \
    Set-Item WSMan:\localhost\Client\TrustedHosts       -Value '*'   -Force; \
    Write-Host '[WinRM] Started'; \
    \
    # Web — PeopleCore HR Portal \
    Write-Host '[PeopleCore] Nexus Dynamics HR Services are ONLINE'; \
    C:\Python311\Scripts\waitress-serve.exe --port=8080 app:app"
