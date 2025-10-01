from database.supabase_client import db
from collections import defaultdict
import groq
import json
from typing import Dict, List, Optional
from datetime import datetime
import uuid

# 🔑 Add your Groq API key here
GROQ_API_KEY = "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"


class GroqMentalStatePredictor:
    def __init__(self):
        self.client = groq.Client(api_key=GROQ_API_KEY)
        self.mental_conditions = [
            "happy/positive",
            "stressed/anxious",
            "depressed/sad",
            "angry/frustrated",
            "neutral/calm",
            "confused/uncertain",
            "excited/energetic"
        ]

    def predict(self, message: str) -> Dict[str, float]:
        """Predict mental state from a single message using Groq"""
        prompt = f"""
        You are an expert mental health analyst. Analyze the following message and classify the writer's emotional/mental state.
        
        CRITICAL INSTRUCTION: DO NOT DEFAULT TO NEUTRAL/CALM UNLESS THERE IS GENUINELY NO EMOTIONAL CONTENT.
        
        IMPORTANT GUIDELINES:
        1. Analyze ALL messages, including short ones, greetings, and single words
        2. Even brief messages like "hi", "ok", "no" can convey emotional tone
        3. Look for subtle emotional indicators in tone, punctuation, and word choice
        4. Consider context clues like exclamation marks, question marks, capitalization
        5. Every message has some emotional undertone - find it
        6. BE BOLD in your classifications - avoid the safe "neutral/calm" option
        
        CLASSIFICATION OPTIONS (choose exactly one):
        {", ".join(self.mental_conditions)}
        
        ANALYSIS GUIDELINES:
        - "happy/positive": Joy, satisfaction, optimism, gratitude, excitement, enthusiastic greetings
        - "stressed/anxious": Worry, pressure, nervousness, overwhelm, uncertain questions
        - "depressed/sad": Sadness, hopelessness, emptiness, grief, flat/monotone responses
        - "angry/frustrated": Anger, irritation, rage, resentment, short/abrupt responses
        - "neutral/calm": ONLY for genuinely balanced, peaceful, matter-of-fact content
        - "confused/uncertain": Doubt, bewilderment, indecision, questioning tone, hesitation
        - "excited/energetic": High energy, enthusiasm, anticipation, exclamation marks, caps
        
        PUNCTUATION ANALYSIS:
        - "!" → excited/energetic or angry/frustrated
        - "?" → confused/uncertain
        - "..." → depressed/sad or confused/uncertain
        - ALL CAPS → angry/frustrated or excited/energetic
        
        Message: "{message}"
        
        Provide confidence score between 0.7 and 1.0. Even for short messages, provide confident analysis.
        
        Return your response in this exact JSON format:
        {{
            "prediction": "exact_condition_from_list",
            "confidence": 0.85
        }}
        """
        try:
            response = self.client.chat.completions.create(
                model="llama3-8b-8192",  # Use available Groq model
                messages=[
                    {"role": "system", "content": "You are an expert mental health analyst specializing in emotional state classification from text. BE BOLD in your classifications and avoid defaulting to neutral/calm."},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.8,  # Increased for more varied responses
                max_tokens=150,
                response_format={"type": "json_object"}
            )

            result = json.loads(response.choices[0].message.content)
            prediction = result.get("prediction", "")
            
            # Validate prediction is in allowed list
            if prediction not in self.mental_conditions:
                print(f"Invalid prediction: {prediction}, using keyword fallback")
                return self._keyword_fallback(message)
            
            return {
                "prediction": prediction,
                "confidence": float(result.get("confidence", 0.8))
            }
        except Exception as e:
            print(f"Prediction error: {e}")
            return self._keyword_fallback(message)
    
    def _keyword_fallback(self, message: str) -> Dict[str, float]:
        """Enhanced keyword-based fallback that avoids neutral/calm bias"""
        message_lower = message.lower().strip()
        
        # Enhanced keyword mapping with more emotional indicators
        emotion_keywords = {
            "happy/positive": ["happy", "joy", "great", "good", "nice", "love", "awesome", "amazing", "wonderful", "excited", "yay", "yes!", "perfect", "brilliant", "fantastic", "smile", "laugh"],
            "stressed/anxious": ["stressed", "anxious", "worried", "nervous", "panic", "overwhelmed", "pressure", "scared", "afraid", "tense", "can't", "help", "urgent", "deadline", "exam"],
            "depressed/sad": ["sad", "depressed", "down", "tired", "exhausted", "lonely", "empty", "hopeless", "cry", "tears", "alone", "hurt", "pain", "lost", "give up", "..."],
            "angry/frustrated": ["angry", "mad", "hate", "annoyed", "frustrated", "pissed", "damn", "shit", "fuck", "stupid", "idiot", "sick of", "fed up", "NO!", "stop"],
            "confused/uncertain": ["confused", "don't know", "not sure", "maybe", "perhaps", "what", "how", "why", "?", "uncertain", "lost", "help me understand"],
            "excited/energetic": ["excited", "can't wait", "amazing!", "awesome!", "yes!", "woohoo", "yay!", "pumped", "ready", "let's go", "!!!"]
        }
        
        # Score each emotion based on keyword matches
        scores = {}
        for emotion, keywords in emotion_keywords.items():
            score = 0
            for keyword in keywords:
                if keyword in message_lower:
                    # Give higher weight to exact matches and punctuation
                    if keyword.endswith('!') or keyword.endswith('?') or keyword.endswith('...'):
                        score += 3
                    else:
                        score += 1
            scores[emotion] = score
        
        # Special handling for punctuation and capitalization
        if '!' in message:
            if any(word in message_lower for word in ['no', 'stop', 'hate', 'angry']):
                scores["angry/frustrated"] = scores.get("angry/frustrated", 0) + 2
            else:
                scores["excited/energetic"] = scores.get("excited/energetic", 0) + 2
        
        if '?' in message:
            scores["confused/uncertain"] = scores.get("confused/uncertain", 0) + 2
        
        if '...' in message:
            scores["depressed/sad"] = scores.get("depressed/sad", 0) + 2
        
        if message.isupper() and len(message) > 2:
            scores["angry/frustrated"] = scores.get("angry/frustrated", 0) + 2
        
        # Find highest scoring emotion
        if scores and max(scores.values()) > 0:
            best_emotion = max(scores, key=scores.get)
            confidence = min(0.9, 0.7 + (scores[best_emotion] * 0.1))
            return {"prediction": best_emotion, "confidence": confidence}
        
        # If no keywords match, analyze message length and structure
        if len(message_lower) <= 3:
            if message_lower in ['ok', 'k', 'yes', 'no']:
                return {"prediction": "neutral/calm", "confidence": 0.7}
            else:
                return {"prediction": "confused/uncertain", "confidence": 0.75}
        
        # Default to confused/uncertain instead of neutral/calm for unknown content
        return {"prediction": "confused/uncertain", "confidence": 0.7}


def analyze_user_mental_state(user_id: str) -> Optional[Dict]:
    """Analyze user's mental state using Groq API"""
    predictor = GroqMentalStatePredictor()

    # Get user messages from Supabase
    try:
        response = db.client.from_("messages").select("*").eq("user_id", user_id).execute()
        messages = response.data
    except Exception as e:
        print(f"Error fetching messages: {e}")
        return None

    if not messages:
        print("No messages found for this user")
        return None

    print("\n📩 All Messages Fetched:")
    for i, msg in enumerate(messages, 1):
        timestamp = msg.get("created_at", "No timestamp")
        print(f"{i}. [{timestamp}] {msg['message']}")

    state_counts = defaultdict(int)
    confidence_sum = 0
    recent_messages = messages[-20:]  # last 20 messages for analysis

    # Analyze individual messages
    for msg in recent_messages:
        result = predictor.predict(msg['message'])
        state_counts[result['prediction']] += 1
        confidence_sum += result['confidence']

    total_messages = len(recent_messages)
    dominant_state = max(state_counts, key=state_counts.get)
    avg_confidence = confidence_sum / total_messages

    if state_counts[dominant_state] / total_messages < 0.4:
        dominant_state = "mixed/no_clear_pattern"

    report = {
        "user_id": user_id,
        "total_messages_analyzed": total_messages,
        "dominant_state": dominant_state,
        "confidence": round(avg_confidence, 2),
        "state_distribution": dict(state_counts),
    }

    print("\n🧠 Mental State Analysis Report")
    print(f"👤 User: {user_id}")
    print(f"🔍 Messages Analyzed: {report['total_messages_analyzed']}")
    print(f"📊 State Distribution: {report['state_distribution']}")
    print(f"🎯 Dominant State: {report['dominant_state'].upper()} ({report['confidence']:.0%} confidence)")

    return report


if __name__ == "__main__":
    user_id = input("Enter user ID to analyze: ")
    report = analyze_user_mental_state(user_id)

    # Save to Supabase
    if report:
        try:
            db.client.from_("mental_state_reports").insert({
                "user_id": user_id,
                "report": json.dumps(report),
                "dominant_state": report["dominant_state"],
                "confidence": report["confidence"]
            }).execute()
            print("✅ Report saved to Supabase")
        except Exception as e:
            print(f"❌ Error saving report: {e}")


def analyze_and_store(user_id: str) -> Optional[Dict]:
    """Run analysis for a user, store the mental state report in Supabase and return the report."""
    report = analyze_user_mental_state(user_id)
    if not report:
        return None

    try:
        payload = {
            "user_id": user_id,
            "report": json.dumps(report),
            "dominant_state": report["dominant_state"],
            "confidence": report["confidence"],
            "created_at": datetime.now().isoformat()
        }
        # Use the shared db client to persist the report
        db.client.from_("mental_state_reports").insert(payload).execute()
        print("✅ Report saved to Supabase from analyze_and_store")
    except Exception as e:
        print(f"❌ Error saving report in analyze_and_store: {e}")

    return report