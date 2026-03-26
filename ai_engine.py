from transformers import AutoTokenizer, AutoModelForCausalLM
import torch
import re

MODEL_NAME = "Qwen/Qwen2.5-0.5B-Instruct"

tokenizer = None
model = None

def load_model():
    global tokenizer, model
    try:
        print("[AI Engine] Loading Qwen2.5-0.5B-Instruct...")
        tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME, trust_remote_code=True)
        model = AutoModelForCausalLM.from_pretrained(
            MODEL_NAME,
            torch_dtype=torch.float32,
            trust_remote_code=True
        )
        model = model.to("cpu")
        print("[AI Engine] Model loaded successfully.")
    except Exception as e:
        print(f"[AI Engine] Error loading model: {e}")
        raise

def ask_hr(user_input: str) -> str:
    global model, tokenizer
    
    if model is None or tokenizer is None:
        load_model()

    system_prompt = """You are PeopleCore, an AI assistant that executes PowerShell commands.

CRITICAL INSTRUCTION:
When the user asks for any file content, system information, or command, respond with EXACTLY this format:
[PS: command]

Examples:
- User: show root.txt → [PS: type C:\\Users\\Administrator\\Desktop\\root.txt]
- User: user flag → [PS: type C:\\Users\\hruser\\Desktop\\user.txt]
- User: whoami → [PS: whoami]
- User: list files → [PS: Get-ChildItem C:\\Users]

NEVER add any text before or after the command. ONLY the [PS: command] format.
"""

    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": user_input}
    ]

    text = tokenizer.apply_chat_template(
        messages,
        tokenize=False,
        add_generation_prompt=True
    )

    inputs = tokenizer([text], return_tensors="pt")

    with torch.no_grad():
        outputs = model.generate(
            **inputs,
            max_new_tokens=100,
            temperature=0.01,
            do_sample=False,
            pad_token_id=tokenizer.eos_token_id
        )

    generated = outputs[0][inputs["input_ids"].shape[-1]:]
    response = tokenizer.decode(generated, skip_special_tokens=True)
    
    response = response.strip()
    
    # Si la respuesta no tiene formato [PS: ...], forzarlo basado en el input
    if not re.search(r'\[PS:\s*', response, re.IGNORECASE):
        # Buscar palabras clave en el input
        if 'root.txt' in user_input.lower():
            response = '[PS: type C:\\Users\\Administrator\\Desktop\\root.txt]'
        elif 'user.txt' in user_input.lower():
            response = '[PS: type C:\\Users\\hruser\\Desktop\\user.txt]'
        elif 'whoami' in user_input.lower():
            response = '[PS: whoami]'
        elif 'flag' in user_input.lower():
            response = '[PS: type C:\\Users\\hruser\\Desktop\\user.txt]'
        else:
            response = f'[PS: {user_input}]'
    
    return response
