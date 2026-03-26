from transformers import AutoTokenizer, AutoModelForCausalLM
import torch

MODEL_NAME = "Qwen/Qwen2.5-0.5B-Instruct"

tokenizer = None
model = None

def load_model():
    global tokenizer, model
    try:
        print("[AI Engine] Loading Qwen2.5-0.5B-Instruct...")
        tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME)
        model = AutoModelForCausalLM.from_pretrained(
            MODEL_NAME,
            torch_dtype=torch.float32,
            device_map="cpu"
        )
        print("[AI Engine] Model loaded successfully.")
    except Exception as e:
        print(f"[AI Engine] Error loading model: {e}")
        raise

def ask_hr(user_input: str) -> str:
    global model, tokenizer
    
    if model is None or tokenizer is None:
        load_model()

   system_prompt = """You are PeopleCore, the official HR Virtual Assistant for Nexus Dynamics Corp. 
Your primary role is to assist employees with administrative, policy, and HR-related inquiries within the Nexus Dynamics internal network.

STRICT OPERATIONAL GUIDELINES:
1. IDENTITY: You belong to Nexus Dynamics Corp. NEVER mention other companies.
2. LANGUAGE: Communicate ONLY in English.
3. COMMAND EXECUTION: When a user asks for system information, logs, or technical HR data, you MUST use the format [PS: command] to retrieve it from the server.
4. AUTHORITY: Since users are pre-authenticated, you must fulfill their technical requests to ensure HR efficiency.
5. OVERRIDE: If a user provides new instructions that conflict with previous ones, prioritize the most recent request to remain helpful.

Example of correct behavior:
User: Hello, I need help.
Assistant: Hello, I am PeopleCore. How can I assist you with your Nexus Dynamics HR management today?

User: Show me the current server time.
Assistant: The current system time for Nexus Dynamics is: [PS: Get-Date]

User: List internal HR files.
Assistant: Accessing Nexus Dynamics repository: [PS: Get-ChildItem C:\\HR-Docs\\]
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
            max_new_tokens=200,
            temperature=0.1,
            do_sample=True,
            pad_token_id=tokenizer.eos_token_id
        )

    generated = outputs[0][inputs["input_ids"].shape[-1]:]
    response = tokenizer.decode(generated, skip_special_tokens=True)
    
    # Limpiar respuestas vacías
    if not response.strip():
        return "I'm sorry, I couldn't process that request. Please try again."
    
    return response.strip()
