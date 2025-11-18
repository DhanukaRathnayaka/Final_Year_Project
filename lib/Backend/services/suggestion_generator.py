from fastapi import APIRouter, HTTPException
import logging
from pydantic import BaseModel
from typing import List
import openai
from openai import OpenAI
from uuid import UUID
import os
from pathlib import Path
from config.settings import GROQ_API_KEY

router = APIRouter()

# Configure module logger
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

# Configure Groq API key
api_key = GROQ_API_KEY
if not api_key:
    raise ValueError("GROQ_API_KEY not found in environment variables")

# Create a Groq client for API calls
from groq import Groq
client = Groq(api_key=api_key)

class ConversationRequest(BaseModel):
    messages: List[str]
    user_id: str
    conversation_id: str

class SuggestionResponse(BaseModel):
    user_id: str
    conversation_id: str
    suggestions: List[str]

@router.post("/generate_suggestions")
async def generate_suggestions(request: ConversationRequest) -> SuggestionResponse:
    try:
        if not request.messages:
            raise HTTPException(
                status_code=400,
                detail="No messages provided in the conversation"
            )
            
        # Prepare conversation context for the LLM
        conversation_text = "\n".join(request.messages)
        
        if not api_key:
            raise HTTPException(
                status_code=500,
                detail="Groq API key not configured"
            )
        
        try:
            # Call Groq API to generate suggestions
            response = client.chat.completions.create(
                model="gemma2-9b-it",  # Using Gemma 2 model
                messages=[
                    {
                        "role": "system",
                        "content": "You are a mental health assistant. Based on the conversation, provide 5 short, practical suggestions to help improve the user's mental well-being. Each suggestion should be a single sentence."
                    },
                    {
                        "role": "user",
                        "content": f"Based on this conversation, provide 5 helpful suggestions:\n{conversation_text}"
                    }
                ],
                temperature=0.7,
                max_tokens=200
            )

            # Log raw response for debugging (safe repr)
            try:
                logger.info(f"OpenAI raw response: {repr(response)}")
            except Exception:
                logger.info("OpenAI response received (could not repr)")
        except Exception as e:
            # Some installed versions of the openai package do not expose
            # openai.error.OpenAIError. Log full exception and return a useful
            # message to the client.
            logger.exception("OpenAI API call failed")
            raise HTTPException(status_code=500, detail=f"OpenAI API error: {e}")
            
        # Extract and process suggestions from multiple possible response shapes.
        def _extract_text_from_response(resp):
            # Try attribute access (newer client objects)
            try:
                choices = getattr(resp, 'choices', None)
                if choices:
                    first = choices[0]
                    # New client may expose message.content
                    msg = getattr(first, 'message', None)
                    if msg is not None:
                        content = getattr(msg, 'content', None)
                        if content:
                            return content
                    # Try dict-like access on choice
                    try:
                        # Some responses are dict-like
                        cdict = first if isinstance(first, dict) else getattr(first, '__dict__', None)
                        if cdict:
                            # nested dict path
                            if isinstance(cdict, dict):
                                return cdict.get('message', {}).get('content') or cdict.get('text')
                            else:
                                # try attribute access fallback
                                return getattr(first, 'text', None)
                    except Exception:
                        pass
                # Try top-level dict-like access
                if isinstance(resp, dict):
                    choices = resp.get('choices')
                    if choices and len(choices) > 0:
                        c0 = choices[0]
                        if isinstance(c0, dict):
                            return c0.get('message', {}).get('content') or c0.get('text')
                # Last resort: string representation
                return str(resp)
            except Exception:
                return None

        raw_text = _extract_text_from_response(response)
        if not raw_text:
            raise HTTPException(status_code=500, detail="Failed to generate meaningful suggestions (empty response)")

        # Split into suggestions lines
        raw_suggestions = raw_text.strip().split("\n")
        # Clean up suggestions (remove numbering if present)
        suggestions = [s.strip().lstrip("0123456789.- ") for s in raw_suggestions if s.strip()][:5]

        if len(suggestions) < 1:
            raise HTTPException(
                status_code=500,
                detail="No valid suggestions could be generated"
            )

        return SuggestionResponse(
            user_id=request.user_id,
            conversation_id=request.conversation_id,
            suggestions=suggestions
        )

    except Exception as e:
        # Log and return the exception message; ensure non-empty detail
        logger.exception("Unhandled error in generate_suggestions")
        text = str(e)
        if not text:
            text = f"{e.__class__.__name__}: (no message)"
        raise HTTPException(status_code=500, detail=text)

# When imported by the main FastAPI app, the router will be included there.
# For local testing you can run this module directly, but prefer running the
# main `app.py` server which includes all routers.
if __name__ == "__main__":
    import uvicorn
    # Run this router as a standalone app for quick testing
    from fastapi import FastAPI
    test_app = FastAPI()
    test_app.include_router(router)
    uvicorn.run(test_app, host="0.0.0.0", port=8000, log_level="info")
