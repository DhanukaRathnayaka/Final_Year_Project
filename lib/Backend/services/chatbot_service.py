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
import logging
from config.settings import GROQ_API_KEY

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Available Groq models
MODELS = {
    "default": "llama-3.1-8b-instant",
    "llama-3.1-8b-instant": "llama-3.1-8b-instant",
    "Llama3.1-70B": "llama3.1-70b-versatile",
    "llama2-70b-4096": "groq/compound"  # alias for frontend compatibility
}

# Initialize router
router = APIRouter()

# Initialize Groq client
if not GROQ_API_KEY:
    raise ValueError("GROQ_API_KEY not found in environment variables")

logger.info(f"Found GROQ_API_KEY: {'*' * 4}...{'*' * 4}")

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
    logger.warning("Continuing without Groq API connection. Chat functionality may not work.")
    groq_client = None

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
    dataset_path = os.path.join(os.path.dirname(__file__), "..", "models", "chatbot_dataset.json")
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
    if groq_client is None:
        logger.warning("Groq API is not available, using fallback responses")
        raise Exception("Groq client not initialized")
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
        raise Exception(f"Groq API error: {str(e)}")

# Fallback responses for common mental health concerns
FALLBACK_RESPONSES = {
    "sad": [
        "It's okay to feel sad sometimes. Sadness is a natural emotion, and acknowledging it is an important first step. Have you thought about what might help lift your spirits? Sometimes even a small change, like taking a walk or talking to someone you trust, can make a difference.",
        "I hear that you're feeling sad. That takes courage to share. Remember, this feeling is temporary, and you have strength within you to get through this. Is there someone you care about that you could reach out to?"
    ],
    "anxious": [
        "Anxiety can feel overwhelming, but you're not alone in feeling this way. Try taking deep breaths - breathing slowly can help calm your nervous system. Focus on what you can control right now, and remember that this feeling will pass.",
        "Feeling anxious is tough, but there are things that can help. Try breaking down what's worrying you into smaller pieces. Sometimes taking it one step at a time makes it feel more manageable. You've got this!"
    ],
    "stressed": [
        "Stress can be really heavy. When you're feeling overwhelmed, it helps to pause and take care of yourself. Even small acts like drinking water, stretching, or stepping outside can make a difference. What's one thing you could do right now to ease some of that stress?",
        "You're carrying a lot right now, and that's understandable. Remember to be kind to yourself. Breaking your tasks into smaller pieces or asking for help isn't weakness - it's wisdom. You're doing better than you think."
    ],
    "depressed": [
        "Depression is a real struggle, and I'm glad you're reaching out. It might not feel like it right now, but things can get better. Have you considered talking to someone - a friend, family member, or counselor? Sometimes sharing the load makes it lighter.",
        "What you're feeling matters, and you matter too. Depression can make everything feel hopeless, but that's the depression talking, not the truth. Consider doing one small thing today that brings you even a tiny bit of comfort."
    ],
    "angry": [
        "It's okay to feel angry - that's a valid emotion. When you're feeling this way, try giving yourself permission to feel it without judgment. Sometimes expressing it through exercise, writing, or talking helps. What do you think might help you right now?",
        "Anger often comes from pain or feeling unheard. Both of those things are real. Try taking some space if you need it, or find a constructive way to express what you're feeling. You deserve to be heard."
    ],
    "lonely": [
        "Loneliness is painful, and I'm glad you're reaching out, even here. Remember that you're not truly alone - others care about you, even if they're not right beside you now. Could you reach out to someone today, even just to say hello?",
        "Feeling lonely is so hard. One thing that might help is reaching out to someone - even a short message to a friend can create connection. You deserve companionship and support. Is there someone you could talk to?"
    ],
    "overwhelmed": [
        "When everything feels like too much, it helps to slow down and take things one at a time. You don't have to handle everything right now. What's the ONE thing you could focus on today? Start there.",
        "Feeling overwhelmed means you care deeply about things, but it also means it's time to pause. You can't pour from an empty cup. What's one thing you could let go of or ask for help with?"
    ],
    "helpless": [
        "Feeling helpless is incredibly difficult. But here's the thing - you reaching out shows you still have power. Even if things feel out of control, there's usually something small you can do. What's one small thing you could try?",
        "You're not as helpless as you feel right now. Depression and despair can make us believe that, but it's not true. You have more strength than you realize. What would help you see that?"
    ],
    "hopeless": [
        "Hopelessness is a heavy weight to carry. But despair can be a liar - it makes us believe things are impossible when they're not. Would you be willing to reach out to someone who cares about you? You deserve support.",
        "I know things feel dark right now, but darkness is not permanent. Hope might feel far away, but it exists. Please reach out to someone - a friend, family member, or counselor. You matter, and this matters."
    ]
}

def get_fallback_response(user_message: str) -> Optional[str]:
    """Get a fallback response based on keywords in the message."""
    user_message_lower = user_message.lower()
    
    # Check for keyword matches
    for keyword, responses in FALLBACK_RESPONSES.items():
        if keyword in user_message_lower:
            return random.choice(responses)
    
    # Generic fallback responses
    generic_responses = [
        "Thank you for sharing with me. It sounds like you're going through something meaningful right now. I'm here to listen and support you however I can. What matters most to you at this moment?",
        "I appreciate you opening up. Your feelings are valid and important. While I'm here to listen, please remember that talking to someone you trust - a friend, family, or professional - can also be really helpful.",
        "You've reached out, and that's important. I want to support you as best as I can. Is there something specific that's on your mind that you'd like to talk about?"
    ]
    return random.choice(generic_responses)

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

        # Try to use AI first, fallback to dataset/generic responses
        try:
            if groq_client is not None:
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
                ai_response = query_groq(selected_model, prompt)
                response = clean_response(ai_response, crisis_mode)
                logger.info("Generated response using Groq API")
                return ChatResponse(response=response)
            else:
                logger.info("Groq API not available, using fallback responses")
                # Use fallback responses
                fallback = get_fallback_response(request.message)
                if fallback:
                    return ChatResponse(response=fallback)
                else:
                    return ChatResponse(response="I'm here to listen and support you. Can you tell me more about what's on your mind?")
                
        except Exception as e:
            logger.warning(f"Error with Groq API, falling back to dataset responses: {e}")
            # Use fallback responses when Groq fails
            fallback = get_fallback_response(request.message)
            if fallback:
                return ChatResponse(response=fallback)
            else:
                return ChatResponse(response="I'm here to listen and support you. Can you tell me more about what's on your mind?")

    except Exception as e:
        logger.error(f"Error in chat endpoint: {e}")
        return ChatResponse(response="I care about what you're sharing. Could you tell me a bit more?")