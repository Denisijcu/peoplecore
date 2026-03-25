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
