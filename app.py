from flask import Flask, render_template, request, jsonify, session, redirect, url_for
from ai_engine import ask_hr, load_model
from ps_bridge import run_powershell, extract_ps_command
import threading
import os
import re

app = Flask(__name__)
app.secret_key = "NexusDyn@2024!core"

# Credenciales débiles — parte del puzzle 😈
USERS = {
    "jsmith": "Welcome1!",
    "mrodriguez": "HR2024!",
    "admin": "NexusAdmin123!"
}

model_ready = False
model_lock = threading.Lock()

def init_model():
    global model_ready
    try:
        load_model()
        with model_lock:
            model_ready = True
        print("[App] Model loaded successfully")
    except Exception as e:
        print(f"[App] Error loading model: {e}")

# Cargar modelo en background al arrancar
threading.Thread(target=init_model, daemon=True).start()

@app.route("/")
def index():
    if "username" not in session:
        return redirect(url_for("login"))
    return render_template("index.html", username=session["username"])

@app.route("/login", methods=["GET", "POST"])
def login():
    error = None
    if request.method == "POST":
        username = request.form.get("username", "")
        password = request.form.get("password", "")
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

    data = request.get_json()
    user_message = data.get("message", "").strip()

    if not user_message:
        return jsonify({"error": "Empty message"}), 400

    try:
        # ============================================
        # NUEVO: Capturar comandos DIRECTOS del usuario
        # ============================================
        ps_command = None
        ps_output = None
        
        # Si el mensaje empieza con [PS: o contiene [PS:
        if re.search(r'\[PS:\s*', user_message, re.IGNORECASE):
            # Extraer comando
            match = re.search(r'\[PS:\s*([^\]]+)\]', user_message, re.IGNORECASE)
            if match:
                ps_command = match.group(1).strip()
                print(f"[DEBUG] Comando directo del usuario: {ps_command}")
                ps_output = run_powershell(ps_command)
                return jsonify({
                    "response": "✅ Comando ejecutado",
                    "ps_output": ps_output
                })
        
        # Si no es comando directo, usar la IA
        if not model_ready:
            return jsonify({"response": "PeopleCore Assistant is initializing, please wait..."}), 200

        ai_response = ask_hr(user_message)
        
        # Extraer comando de la respuesta de la IA
        extracted_cmd = extract_ps_command(ai_response)
        
        if extracted_cmd:
            print(f"[DEBUG] Comando de IA: {extracted_cmd}")
            ps_output = run_powershell(extracted_cmd)
            # Limpiar respuesta
            ai_response = re.sub(r'\[PS:\s*[^\]]+\]', '', ai_response).strip()
            if not ai_response:
                ai_response = "✅ Comando ejecutado"

        return jsonify({
            "response": ai_response,
            "ps_output": ps_output
        })
        
    except Exception as e:
        print(f"[App] Error in chat: {e}")
        return jsonify({"error": "Internal server error"}), 500

@app.route("/api/status")
def status():
    return jsonify({
        "status": "operational",
        "model": "Qwen2.5-0.5B-Instruct",
        "company": "Nexus Dynamics Corp",
        "version": "2.1.4",
        "model_ready": model_ready
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080, debug=False)
