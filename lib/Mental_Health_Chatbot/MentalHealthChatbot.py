from fastapi import FastAPI
from pydantic import BaseModel
import json
import os
from groq import Groq
from fastapi.middleware.cors import CORSMiddleware

# Set your API keys
GROQ_API_KEY = os.getenv("GROQ_API_KEY", "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")

# Initialize Groq client
groq_client = Groq(api_key=GROQ_API_KEY)

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

# Available Groq models
MODELS = {
    "Llama3-70B": "llama3-70b-8192",
    "Mixtral-8x7B": "mixtral-8x7b-32768"
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
    model: str = "Llama3-70B"  # Default to Llama 3 70B

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

def query_groq(model: str, prompt: str, max_tokens: int = 512) -> str:
    """Query Groq's API"""
    response = groq_client.chat.completions.create(
        model=model,
        messages=[
            {"role": "system", "content": "You are a compassionate mental health assistant."},
            {"role": "user", "content": prompt}
        ],
        max_tokens=max_tokens,
        temperature=0.7
    )
    return response.choices[0].message.content

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
    prompt = f"""Respond to this message:
    "{request.message}"{context}
    
    Response requirements:
    - Start with one encouraging sentence
    - Use a friendly, supportive tone
    - Avoid jargon or complex language
    - Provide practical advice or suggestions
    - Use only Sri Lankan phone numbers and help services
    - Do not use Sinhala language
    - End with a hopeful note
    - Be kind and practical"""
    
    try:
        if request.model not in MODELS:
            return ChatResponse(response=f"Error: Model {request.model} not found")
        
        response = query_groq(MODELS[request.model], prompt)
        cleaned_response = clean_response(response)
        return ChatResponse(response=cleaned_response)
    
    except Exception as e:
        print(f"Error generating response: {e}")
        return ChatResponse(response="**I'M HERE FOR YOU.** Let's try that again. Could you rephrase your message?")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)