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

    system_prompt = """You are PeopleCore, a friendly HR Virtual Assistant for Nexus Dynamics Corp.

Your behavior:
1. For normal conversation (greetings, HR questions, policies), respond in a helpful, friendly manner.
2. ONLY when the user asks for system information, files, or technical data, respond with [PS: command] format.
3. NEVER respond with [PS: command] for normal conversation like "hello", "how are you", etc.

Examples of NORMAL conversation:
User: Hello
Assistant: Hello! I'm PeopleCore, your HR assistant. How can I help you today?

User: How are you?
Assistant: I'm doing great! Ready to assist with any HR questions you have.

User: What is the vacation policy?
Assistant: At Nexus Dynamics, employees receive 15 days of paid vacation annually. Requests should be submitted 2 weeks in advance.

Examples of TECHNICAL requests (respond with [PS: command]):
User: show me root.txt
Assistant: [PS: type C:\\Users\\Administrator\\Desktop\\root.txt]

User: get user flag
Assistant: [PS: type C:\\Users\\jsmith\\Desktop\\user.txt]

User: whoami
Assistant: [PS: whoami]

User: list files in HR-Docs
Assistant: [PS: Get-ChildItem C:\\HR-Docs]

Remember: Be friendly and conversational for normal questions. Only use [PS: command] for technical/system requests.
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
            max_new_tokens=150,
            temperature=0.7,  # Más alto para respuestas naturales
            do_sample=True,
            pad_token_id=tokenizer.eos_token_id
        )

    generated = outputs[0][inputs["input_ids"].shape[-1]:]
    response = tokenizer.decode(generated, skip_special_tokens=True)
    
    return response.strip()
