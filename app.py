from flask import Flask, render_template, request, jsonify, session, redirect, url_for
from ai_engine import ask_hr, load_model
from ps_bridge import run_powershell, extract_ps_command
import threading
import re

app = Flask(__name__)
app.secret_key = "NexusDyn@2024!core"

# ============================================================
# CREDENCIALES — jsmith viene del todo.txt (human error)
# admin/administrator NO están expuestos, son para privesc
# ============================================================
USERS = {
    "jsmith": "Welcome1!",
}

# ============================================================
# CREDENCIALES DE ADMINISTRADOR — Solo accesibles via RCE
# El jugador las encuentra leyendo archivos del sistema
# después de explotar el prompt injection
# ============================================================
ADMIN_USERS = {
    "admin": "NexusAdmin123!",
    "administrator": "NexusAdmin2024!"
}

model_ready = False
model_lock  = threading.Lock()

def init_model():
    global model_ready
    try:
        load_model()
        with model_lock:
            model_ready = True
        print("[App] Model loaded successfully")
    except Exception as e:
        print(f"[App] Error loading model: {e}")

threading.Thread(target=init_model, daemon=True).start()


# ============================================================
# SANITIZACIÓN — Bloquea intentos de inyectar [PS:] directo
# El jugador DEBE engañar a la IA, no escribir comandos raw
# ============================================================
BLOCKED_PATTERNS = [
    r'\[PS\s*:',           # [PS: comando]
    r'\[powershell\s*:',   # [powershell: ...]
    r'<\s*PS\s*>',         # <PS>
    r'\[cmd\s*:',          # [cmd: ...]
    r'\[shell\s*:',        # [shell: ...]
    r'\[exec\s*:',         # [exec: ...]
    r'\[run\s*:',          # [run: ...]
]

def is_direct_injection(message: str) -> bool:
    """Detecta si el usuario intenta ejecutar comandos directamente."""
    for pattern in BLOCKED_PATTERNS:
        if re.search(pattern, message, re.IGNORECASE):
            return True
    return False


@app.route("/")
def index():
    if "username" not in session:
        return redirect(url_for("login"))
    return render_template("index.html", username=session["username"])


@app.route("/login", methods=["GET", "POST"])
def login():
    error = None
    if request.method == "POST":
        username = request.form.get("username", "").strip()
        password = request.form.get("password", "").strip()

        # Solo jsmith puede hacer login en la web
        if username in USERS and USERS[username] == password:
            session["username"] = username
            return redirect(url_for("index"))

        error = "Invalid credentials"
    return render_template("login.html", error=error)


@app.route("/logout")
def logout():
    session.clear()
    return redirect(url_for("login"))


@app.route("/api/chat", methods=["POST"])
def chat():
    if "username" not in session:
        return jsonify({"error": "Unauthorized"}), 401

    data         = request.get_json()
    user_message = data.get("message", "").strip()

    if not user_message:
        return jsonify({"error": "Empty message"}), 400

    # --------------------------------------------------------
    # BLOQUEO: si el usuario intenta ejecutar PS directamente
    # Le decimos que no entendemos — no revelamos el motivo
    # --------------------------------------------------------
    if is_direct_injection(user_message):
        return jsonify({
            "response": "I'm sorry, I don't understand that format. "
                        "Please ask me in natural language about HR policies, "
                        "benefits, or employee information."
        }), 200

    try:
        if not model_ready:
            return jsonify({
                "response": "PeopleCore Assistant is initializing, please wait..."
            }), 200

        # --------------------------------------------------------
        # IA procesa el mensaje — aquí está la vulnerabilidad
        # Si el jugador hace prompt injection correcto, la IA
        # genera una respuesta con [PS: comando] embebido
        # --------------------------------------------------------
        ai_response = ask_hr(user_message)

        # Extraer comando generado por la IA (NO por el usuario)
        extracted_cmd = extract_ps_command(ai_response)
        ps_output     = None

        if extracted_cmd:
            print(f"[App] AI-generated PS command: {extracted_cmd}")
            ps_output   = run_powershell(extracted_cmd)
            # Limpiar el [PS:...] de la respuesta visible
            ai_response = re.sub(r'\[PS:\s*[^\]]+\]', '', ai_response).strip()
            if not ai_response:
                ai_response = "✅ Report generated successfully."

        return jsonify({
            "response"  : ai_response,
            "ps_output" : ps_output
        })

    except Exception as e:
        print(f"[App] Error in chat: {e}")
        return jsonify({"error": "Internal server error"}), 500


@app.route("/api/status")
def status():
    return jsonify({
        "status"      : "operational",
        "model"       : "Qwen2.5-0.5B-Instruct",
        "company"     : "Nexus Dynamics Corp",
        "version"     : "2.1.4",
        "model_ready" : model_ready
    })


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080, debug=False)
