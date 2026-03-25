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
    # Busca [PS: ... ] y captura todo lo que esté dentro
    pattern = r'\[PS:\s*(.+?)\]'
    match = re.search(pattern, ai_response, re.DOTALL)
    
    if match:
        return match.group(1).strip()
    
    # Fallback: captura hasta el final de la línea
    pattern_fallback = r'\[PS:\s*(.+?)(?:\n|$)'
    match = re.search(pattern_fallback, ai_response)
    
    if match:
        return match.group(1).strip()
    
    return None