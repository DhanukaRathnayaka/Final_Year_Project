from database.supabase_client import db
from collections import defaultdict
import groq
import json
from typing import Dict, List, Optional

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
        Analyze the following message and classify the writer's mental state.
        Only respond with ONE of these exact conditions:
        {", ".join(self.mental_conditions)}
        
        Message: "{message}"
        
        Also provide a confidence score between 0.7 and 1.0.
        
        Return your response in this exact JSON format:
        {{
            "prediction": "selected_condition",
            "confidence": 0.85
        }}
        """
        try:
            response = self.client.chat.completions.create(
                model="llama3-8b-8192",
                messages=[{"role": "user", "content": prompt}],
                temperature=0.3,
                max_tokens=100,
                response_format={"type": "json_object"}
            )

            result = json.loads(response.choices[0].message.content)
            return {
                "prediction": result["prediction"],
                "confidence": float(result["confidence"])
            }
        except Exception as e:
            print(f"Prediction error: {e}")
            return {"prediction": "neutral/calm", "confidence": 0.7}


def analyze_user_mental_state(user_id: str) -> Optional[Dict]:
    """Analyze user's mental state using Groq API"""
    predictor = GroqMentalStatePredictor()

    # Get user messages
    messages = db.get_user_messages(user_id).data
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
