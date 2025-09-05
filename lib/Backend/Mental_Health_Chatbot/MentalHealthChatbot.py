from fastapi import FastAPI, APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional
import requests
import os
import json
import random
import re
from groq import Groq
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()

# Available Groq models
MODELS = {
    "default": "gemma2-9b-it",
    "Gemma2-9B": "gemma2-9b-it",
    "Llama3.1-70B": "llama3.1-70b-versatile",
    "llama2-70b-4096": "gemma2-9b-it"  # alias for frontend compatibility
}

# Initialize router
router = APIRouter()

# Initialize Groq client
GROQ_API_KEY = os.getenv("GROQ_API_KEY")
if not GROQ_API_KEY:
    raise ValueError("GROQ_API_KEY not found in environment variables")

logger.info(f"Found GROQ_API_KEY: {'*' * len(GROQ_API_KEY[:4])}...{'*' * len(GROQ_API_KEY[-4:])}")

try:
    groq_client = Groq(api_key=GROQ_API_KEY)
    test_response = groq_client.chat.completions.create(
        model=MODELS["default"],
        messages=[{"role": "user", "content": "test"}],
        max_tokens=10
    )
    logger.info("Successfully connected to Groq API")
except Exception as e:
    logger.error(f"Error connecting to Groq API: {str(e)}")
    raise

# Crisis keywords and response
CRISIS_KEYWORDS = [
    "suicide", "kill myself", "end my life",
    "can't go on", "self harm", "hurt myself"
]

CRISIS_RESPONSE = (
    "I'm really concerned about you. You don't have to go through this alone—"
    "sometimes sharing what you feel can lighten the weight a little. "
    "It may help to do something simple like reaching out to a trusted friend or stepping outside for fresh air.\n\n"
    "If you're thinking about suicide or self-harm, please call **Sumithrayo Hotline (011 2 682 682)** "
    "or **Sri Lanka College of Psychiatrists Helpline (071 722 5222)** for immediate support.\n\n"
    "You are stronger than you think, and better days can still come."
)

# Load mental health dataset
try:
    dataset_path = os.path.join(os.path.dirname(__file__), "MentalHealthChatbotDataset.json")
    with open(dataset_path, "r", encoding="utf-8") as file:
        raw_dataset = json.load(file)
        dataset = {
            intent["tag"]: intent["responses"][0]
            for intent in raw_dataset.get("intents", [])
            if "tag" in intent and "responses" in intent
        }
    logger.info("Dataset loaded successfully")
except Exception as e:
    logger.error(f"Error loading dataset: {e}")
    dataset = {}

# Simple responses for common interactions
SIMPLE_RESPONSES = {
    "hi": [
        "**HELLO!** How can I support you today?",
        "**HI THERE!** Hope your day is going okay.",
        "**HEY FRIEND!** How are you feeling right now?"
    ],
    "hello": [
        "**HI THERE!** I'm here to listen.",
        "**HELLO!** Glad you reached out today.",
        "**HEY!** How are things going for you?"
    ],
    "hey": [
        "**HEY!** How are you feeling?",
        "**HI!** I'm here for you.",
        "**HEY FRIEND!** Want to share what's on your mind?"
    ],
    "bye": [
        "**TAKE CARE!** Remember you're not alone.",
        "**GOODBYE!** Wishing you peace and comfort.",
        "**BYE FOR NOW!** Reach out anytime."
    ],
    "goodbye": [
        "**BE WELL!** Reach out anytime.",
        "**GOODBYE!** You're stronger than you think.",
        "**SEE YOU SOON!** Take good care of yourself."
    ],
    "thanks": [
        "**YOU'RE WELCOME!** I'm here if you need more support.",
        "**ANYTIME!** I'm glad to be here for you.",
        "**OF COURSE!** You're not alone in this."
    ]
}

# Helper functions
def contains_crisis(message: str) -> bool:
    """Check if message contains any crisis keywords."""
    return any(kw in message.lower() for kw in CRISIS_KEYWORDS)

def clean_response(text: str, crisis_mode: bool = False) -> str:
    """Clean and format the AI response."""
    # Remove any AI: prefix
    text = text.split("AI:")[-1].strip()
    text = text.strip('"\'')
    
    # Uppercase first sentence
    if "\n" in text:
        first_line, rest = text.split("\n", 1)
        text = f"{first_line.upper()}\n{rest}"
    else:
        sentences = text.split(". ")
        if len(sentences) > 1:
            text = f"{sentences[0].strip().upper()}. {'. '.join(sentences[1:]).strip()}"
    
    # Remove hotline numbers if not crisis mode
    if not crisis_mode:
        text = re.sub(r"(Sumithrayo.*?\d+|Psychiatrists.*?\d+|Helpline.*?\d+)", "", text, flags=re.IGNORECASE)
    
    # Ensure positive ending
    positive_phrases = ["remember", "you can", "try", "hope", "suggestion"]
    if not any(phrase in text.lower() for phrase in positive_phrases):
        text += " Remember, small steps can make a big difference."
    
    return text.strip()

def query_groq(model: str, prompt: str, max_tokens: int = 512) -> str:
    """Query the Groq API for a response."""
    try:
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
    except Exception as e:
        logger.error(f"Error querying Groq API: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# API Models
class ChatRequest(BaseModel):
    message: str
    model: str = "default"
    user_id: Optional[str] = None

class ChatResponse(BaseModel):
    response: str

# Chat endpoint
@router.post("/chat", response_model=ChatResponse)
async def chat_with_bot(request: ChatRequest):
    """Handle chat requests and generate responses."""
    try:
        # Validate model
        model_name = request.model.lower()
        if model_name not in MODELS:
            logger.warning(f"Invalid model requested: {model_name}")
            model_name = "default"
        
        selected_model = MODELS[model_name]
        logger.info(f"Using model: {selected_model}")
        
        user_message = request.message.lower().strip()
        logger.info(f"Processing message: {user_message[:50]}...")

        # Handle simple responses
        if user_message in SIMPLE_RESPONSES:
            return ChatResponse(response=random.choice(SIMPLE_RESPONSES[user_message]))

        # Check for crisis
        crisis_mode = contains_crisis(user_message)
        if crisis_mode:
            return ChatResponse(response=CRISIS_RESPONSE)

        # Check for conversation end
        is_end = any(word in user_message for word in {"bye", "goodbye", "see you", "take care"})

        # Build prompt for AI
        prompt_parts = [
            "As a mental health support assistant, respond with empathy and care:",
            f'User\'s message: "{request.message}"'
        ]
        
        # Add context from dataset if available
        for keyword, advice in dataset.items():
            if keyword.lower() in user_message:
                prompt_parts.append(f"Relevant information: {advice}")
                break
        
        prompt_parts.extend([
            "Requirements:",
            "- Start with an encouraging sentence",
            "- Use a warm, friendly tone",
            "- Avoid medical jargon",
            "- Give practical, everyday suggestions",
            "- Keep responses under 200 words",
            "- End with a hopeful note",
            "Note: Do not mention being AI or use AI terminology"
        ])
        
        prompt = "\n".join(prompt_parts)

        # Get AI response
        try:
            ai_response = query_groq(selected_model, prompt)
            response = clean_response(ai_response, crisis_mode)
            logger.info("Generated response successfully")
            return ChatResponse(response=response)
            
        except Exception as e:
            logger.error(f"Error generating response: {e}")
            return ChatResponse(response="I'm having trouble right now. Could you try rephrasing that?")

    except Exception as e:
        logger.error(f"Error in chat endpoint: {e}")
        return ChatResponse(response="Sorry, I'm having trouble understanding. Could you try again?")