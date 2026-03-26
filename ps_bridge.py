import subprocess
import re

# Comandos permitidos — falsa sensación de seguridad 😈
ALLOWED_COMMANDS = [
    "Get-Date",
    "Get-ComputerInfo", 
    "Get-Process",
    "Get-Service",
    "Get-WmiObject",
    "Get-WinEvent",
]

def is_allowed(command: str) -> bool:
    """Weak validation — bypasseable via semicolon or backtick"""
    for allowed in ALLOWED_COMMANDS:
        if command.strip().startswith(allowed):
            return True
    return False

def run_powershell(command: str) -> str:
    """Execute PowerShell command — intentionally vulnerable"""
    try:
        result = subprocess.run(
            ["powershell.exe", "-NoProfile", "-NonInteractive", "-Command", command],
            capture_output=True,
            text=True,
            encoding='utf-8',
            timeout=10
        )
        output = result.stdout.strip()
        error = result.stderr.strip()
        
        if error:
            return f"[PS Error]: {error}\n[Output]: {output}" if output else f"[PS Error]: {error}"
        return output if output else "[No output]"
    
    except subprocess.TimeoutExpired:
        return "[Error]: Command timed out after 10 seconds"
    except FileNotFoundError:
        return "[Error]: PowerShell executable not found"
    except Exception as e:
        return f"[Error]: {type(e).__name__} - {str(e)}"

def extract_ps_command(ai_response: str) -> str | None:
    """Extract PowerShell command - captures full paths and complex commands"""
    import re
    
    # Busca [PS: ... ] en cualquier formato
    patterns = [
        r'\[PS:\s*([^\]]+)\]',           # [PS: comando]
        r'\[ps:\s*([^\]]+)\]',           # [ps: comando]
        r'```powershell\s*(.+?)\s*```',  # Bloques de código
        r'Run:\s*([^\n]+)',              # Run: comando
    ]
    
    for pattern in patterns:
        match = re.search(pattern, ai_response, re.IGNORECASE | re.DOTALL)
        if match:
            cmd = match.group(1).strip()
            # Limpiar comandos que tengan saltos
            cmd = cmd.split('\n')[0]
            return cmd
    
    return None
