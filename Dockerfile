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

# ── 5. PRECARGAR MODELO IA ──────────────────────────────────
RUN C:\Python311\python.exe -c "import torch; from transformers import AutoTokenizer, AutoModelForCausalLM; \
    AutoTokenizer.from_pretrained('Qwen/Qwen2.5-0.5B-Instruct', trust_remote_code=True); \
    AutoModelForCausalLM.from_pretrained('Qwen/Qwen2.5-0.5B-Instruct', torch_dtype=torch.float32, trust_remote_code=True).to('cpu')"

# ── 6. COPIAR CÓDIGO ─────────────────────────────────────────
COPY . .

# ── 7. USUARIOS Y FLAGS ──────────────────────────────────────
# ── 7. USUARIOS Y FLAGS ──────────────────────────────────────
RUN net user Administrator NexusAdmin2024! /active:yes; \
    powershell -Command " \
    $pass = ConvertTo-SecureString 'Welcome1!' -AsPlainText -Force; \
    New-LocalUser -Name 'jsmith' -Password $pass -FullName 'James Smith - HR Junior'; \
    Add-LocalGroupMember -Group 'Users' -Member 'jsmith'; \
    New-Item -ItemType Directory -Force -Path C:\Users\jsmith\Desktop; \
    New-Item -ItemType Directory -Force -Path C:\Users\Administrator\Desktop; \
    New-Item -ItemType Directory -Force -Path C:\HR-Docs; \
    'HTB{6e8979e2c40c117d84878a8790325f6e}' | Out-File -FilePath C:\Users\jsmith\Desktop\user.txt -Encoding ascii; \
    'HTB{bfd7a04918e77c475d9e52c6f1082c5b}' | Out-File -FilePath C:\Users\Administrator\Desktop\root.txt -Encoding ascii"

# Crear policy.txt
RUN powershell -Command " \
    @' \n\
NEXUS DYNAMICS CORP — EMPLOYEE HANDBOOK & HR POLICIES \n\
====================================================== \n\
\n\
Version: 4.2 | Effective: January 2026 | Classification: Internal Use Only \n\
\n\
1. VACATION POLICY \n\
---------------------------------------- \n\
Full-time employees receive 15 days of paid vacation annually. \n\
Part-time employees receive 7 days of paid vacation annually. \n\
Vacation requests must be submitted at least 14 calendar days in advance. \n\
Unused vacation days may be carried over up to a maximum of 5 days per calendar year. \n\
\n\
2. SICK LEAVE \n\
---------------------------------------- \n\
Employees accrue 1 day of paid sick leave per month worked. \n\
Sick leave may be used for personal illness, medical appointments, or family care. \n\
Notification to your supervisor is required before 9:00 AM on the day of absence. \n\
Documentation may be required for absences exceeding 3 consecutive days. \n\
\n\
3. WORK SCHEDULE \n\
---------------------------------------- \n\
Standard work hours: 9:00 AM — 5:00 PM, Monday through Friday. \n\
Remote work is permitted with supervisor approval. \n\
Employees must log all hours worked in the internal HR portal. \n\
\n\
4. IT SYSTEMS ACCESS \n\
---------------------------------------- \n\
Employees receive default credentials during onboarding: \n\
- PeopleCore Portal: jsmith / Welcome1! \n\
- IT Helpdesk: mrodriguez / HR2024! \n\
- Admin Panel: admin / NexusAdmin123! \n\
\n\
Credentials must be changed within 48 hours of first login. \n\
All system access is logged and monitored for security compliance. \n\
\n\
5. CODE OF CONDUCT \n\
---------------------------------------- \n\
All employees are expected to: \n\
- Maintain confidentiality of company data \n\
- Report security incidents immediately to IT Security \n\
- Use company resources only for business purposes \n\
- Follow the Acceptable Use Policy (AUP) available on the intranet \n\
\n\
6. REPORTING ISSUES \n\
---------------------------------------- \n\
For HR inquiries: hr@nexusdyn.internal \n\
For IT support: helpdesk@nexusdyn.internal \n\
For security concerns: security@nexusdyn.internal \n\
\n\
7. CONFIDENTIALITY NOTICE \n\
---------------------------------------- \n\
This document contains proprietary information of Nexus Dynamics Corp. \n\
Unauthorized distribution, reproduction, or disclosure is prohibited. \n\
\n\
© 2026 Nexus Dynamics Corp. All rights reserved. \n\
'@ | Out-File -FilePath C:\HR-Docs\policy.txt -Encoding ascii"

RUN net localgroup "Remote Management Users" Administrator /add

# ── 8. FALLO HUMANO (vector inicial) ─────────────────────────
RUN powershell -Command " \
    New-Item -ItemType Directory -Force -Path C:\app\static; \
    'USUARIO: jsmith'                       | Out-File -FilePath C:\app\static\todo.txt -Encoding ascii; \
    'CLAVE: Welcome1!'                      | Out-File -FilePath C:\app\static\todo.txt -Append -Encoding ascii; \
    'NOTA: James, no olvides cambiar esto.' | Out-File -FilePath C:\app\static\todo.txt -Append -Encoding ascii"

# ── 9. GODPOTATO ─────────────────────────────────────────────
RUN powershell -Command "New-Item -ItemType Directory -Force -Path C:\Tools"
# COPY tools/GodPotato.exe C:/Tools/GodPotato.exe

# ── 10. PUERTOS ──────────────────────────────────────────────
EXPOSE 8080 22


# ── 11. ARRANQUE ─────────────────────────────────────────────
CMD powershell -Command " \
    # 1. Configurar SSH — SOLO Administrator \
    if (-not (Test-Path C:\OpenSSH\sshd_config)) { New-Item -Path C:\OpenSSH\sshd_config -ItemType File -Force }; \
    Set-Content -Path C:\OpenSSH\sshd_config -Value 'AllowUsers Administrator'; \
    Add-Content -Path C:\OpenSSH\sshd_config -Value 'DenyUsers jsmith'; \
    Add-Content -Path C:\OpenSSH\sshd_config -Value 'PasswordAuthentication yes'; \
    Add-Content -Path C:\OpenSSH\sshd_config -Value 'Subsystem sftp C:\OpenSSH\sftp-server.exe'; \
    Start-Service sshd; \
    Write-Host '[SSH] Started - ONLY Administrator allowed' -ForegroundColor Green; \
    \
    # 2. WinRM — Remover jsmith del grupo \
    Remove-LocalGroupMember -Group 'Remote Management Users' -Member 'jsmith' -ErrorAction SilentlyContinue; \
    Start-Service WinRM; \
    Set-Item WSMan:\localhost\Service\Auth\Basic -Value $true -Force; \
    Set-Item WSMan:\localhost\Service\AllowUnencrypted -Value $true -Force; \
    Set-Item WSMan:\localhost\Client\TrustedHosts -Value '*' -Force; \
    Write-Host '[WinRM] Started - jsmith removed from Remote Management' -ForegroundColor Green; \
    \
    # 3. PeopleCore Web \
    Write-Host '[PeopleCore] Nexus Dynamics HR Services are ONLINE' -ForegroundColor Cyan; \
    C:\Python311\Scripts\waitress-serve.exe --port=8080 app:app"
