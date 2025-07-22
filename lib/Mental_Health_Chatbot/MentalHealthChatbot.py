from fastapi import FastAPI
from pydantic import BaseModel
import json
import os
from langchain_together import Together
from langchain.llms import Cohere
from fastapi.middleware.cors import CORSMiddleware

# Set your API keys
TOGETHER_API_KEY = os.getenv("TOGETHER_API_KEY", "da20b11f2f9a2f51a62573f274f3a49a37002b67d1f6c511ed56de266ad0271b")
COHERE_API_KEY = os.getenv("COHERE_API_KEY", "your_cohere_api_key_here")

# Load mental health dataset
try:
    with open("MentalHealthChatbotDataset.json", "r", encoding="utf-8") as file:
        dataset = json.load(file)
    print("✅ Dataset loaded successfully")
except Exception as e:
    print(f"❌ Error loading dataset: {e}")
    dataset = {}

# Simple responses for common messages
SIMPLE_RESPONSES = {
    "hi": "**HELLO!** How can I support you today?",
    "hello": "**HI THERE!** I'm here to listen.",
    "hey": "**HEY!** How are you feeling?",
    "bye": "**TAKE CARE!** Remember you're not alone.",
    "goodbye": "**BE WELL!** Reach out anytime.",
    "thanks": "**YOU'RE WELCOME!** I'm here if you need more support."
}

# Initialize AI models
models = {
    "Mistral AI": Together(model="mistralai/Mistral-7B-Instruct-v0.3", together_api_key=TOGETHER_API_KEY),
    "LLaMA 3.3 Turbo": Together(model="meta-llama/Llama-3.3-70B-Instruct-Turbo-Free", together_api_key=TOGETHER_API_KEY),
    "DeepSeek R1": Together(model="deepseek-ai/deepseek-r1-distill-llama-70b-free", together_api_key=TOGETHER_API_KEY),
    "Cohere Command": Cohere(model="command-xlarge", cohere_api_key=COHERE_API_KEY)
}

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class ChatRequest(BaseModel):
    message: str
    model: str = "Mistral AI"

class ChatResponse(BaseModel):
    response: str

def clean_response(text: str) -> str:
    """Clean the AI response to meet our requirements"""
    # Remove any system prompt remnants
    text = text.split("AI:")[-1].strip()
    
    # Ensure first sentence is strong and uppercase (but not entire response)
    if "\n" in text:
        first_line, rest = text.split("\n", 1)
        first_line = first_line.upper()
        text = f"{first_line}\n{rest}"
    else:
        sentences = text.split(".")
        if len(sentences) > 1:
            first_sentence = sentences[0].strip().upper()
            rest = ". ".join(sentences[1:]).strip()
            text = f"{first_sentence}. {rest}"
    
    # Remove any quotation marks
    text = text.replace('"', '').replace("'", "")
    
    # Ensure ends with positive note if not already
    positive_phrases = ["remember", "you can", "try", "hope", "suggestion"]
    if not any(phrase in text.lower() for phrase in positive_phrases):
        text += " Remember, small steps can make a big difference."
    
    return text.strip()

@app.post("/chat", response_model=ChatResponse)
def chat_with_bot(request: ChatRequest):
    user_message = request.message.lower().strip()
    
    # Check for simple responses first
    if user_message in SIMPLE_RESPONSES:
        return ChatResponse(response=SIMPLE_RESPONSES[user_message])
    
    # Add relevant context from dataset
    context = ""
    for keyword, advice in dataset.items():
        if keyword.lower() in user_message:
            context = f"\nRelevant information: {advice}"
            break
    
    # Prepare the prompt
    prompt = f"""You are a compassionate mental health assistant. Respond to this message:
    "{request.message}"{context}
    
    Response requirements:
    - Start with one encouraging sentence
    - Use a friendly, supportive tone
    - Avoid jargon or complex language
    - Provide practical advice or suggestions
    - use only srilankan phonenumbers and help services do not use sinhala language
    - End with a hopeful note
    - Be kind and practical"""
    
    try:
        model = models.get(request.model)
        if not model:
            return ChatResponse(response=f"Error: Model {request.model} not found")
        
        response = model.invoke(prompt, max_tokens=150)
        cleaned_response = clean_response(response)
        return ChatResponse(response=cleaned_response)
    
    except Exception as e:
        return ChatResponse(response="**I'M HERE FOR YOU.** Let's try that again. Could you rephrase your message?")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)