# recommendations.py
import os
import re
import uuid
import json
import time
from collections import defaultdict
from datetime import datetime
from typing import Dict, List, Optional

import groq
from supabase import create_client, Client

# config/settings can provide constants, fallback to env
try:
    from config.settings import SUPABASE_URL, SUPABASE_KEY, GROQ_API_KEY  # type: ignore
except Exception:
    SUPABASE_URL = os.environ.get("SUPABASE_URL")
    SUPABASE_KEY = os.environ.get("SUPABASE_KEY")
    GROQ_API_KEY = os.environ.get("GROQ_API_KEY")

if not SUPABASE_URL or not SUPABASE_KEY:
    raise ValueError("SUPABASE_URL and SUPABASE_KEY must be set (env or config.settings)")

# Initialize Supabase client
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)


class GroqMentalStatePredictor:
    """
    Predict mental state using Groq LLM with a robust JSON schema and
    heuristic fallback if LLM fails or returns unexpected output.
    """

    def __init__(self, api_key: Optional[str] = None):
        api_key = api_key or GROQ_API_KEY or os.environ.get("GROQ_API_KEY")
        if not api_key:
            raise ValueError("GROQ_API_KEY environment variable is not set")
        self.client = groq.Client(api_key=api_key)
        self.mental_conditions = [
            "happy/positive",
            "stressed/anxious",
            "depressed/sad",
            "angry/frustrated",
            "neutral/calm",
            "confused/uncertain",
            "excited/energetic",
        ]

    def _build_prompt(self, message: str) -> str:
        # Keep prompt short and explicit; require exact JSON keys
        conditions = ", ".join(self.mental_conditions)
        prompt = f"""
Analyze the following message and choose exactly ONE of these conditions:
{conditions}

Definitions (brief):
- happy/positive: joy, gratitude, achievement, optimism
- stressed/anxious: worry, pressure, panic, racing thoughts, overwhelm
- depressed/sad: hopelessness, low energy, emptiness, loss of interest
- angry/frustrated: irritation, anger, blame, strong negative reaction
- neutral/calm: balanced mood, routine activities, no strong emotion
- confused/uncertain: doubt, unclear thoughts, asking what to do
- excited/energetic: high energy, eagerness, future-focused excitement

Return EXACTLY a JSON object (no extra text) with keys:
{{"prediction": "<one of the conditions above>", "confidence": 0.XX}}

Message: "{message}"
Confidence: a number between 0.70 and 1.00
"""
        return prompt

    def _safe_parse_json(self, raw: str) -> Optional[Dict]:
        """
        Try to parse JSON robustly. Accept raw JSON or a JSON object embedded
        inside text (use regex to find {...}).
        """
        if not raw:
            return None

        # First try direct parse
        try:
            obj = json.loads(raw)
            if isinstance(obj, dict):
                return obj
        except Exception:
            pass

        # Try to extract first JSON object in string
        match = re.search(r"(\{(?:[^{}]|(?R))*\})", raw, flags=re.DOTALL)
        if match:
            candidate = match.group(1)
            try:
                obj = json.loads(candidate)
                if isinstance(obj, dict):
                    return obj
            except Exception:
                pass

        return None

    def normalize_prediction(self, pred: str) -> Optional[str]:
        if not pred or not isinstance(pred, str):
            return None
        p = pred.strip().lower()

        # direct canonical match
        if p in self.mental_conditions:
            return p

        # mapping common words/phrases to canonical labels
        mapping = {
            "happy": "happy/positive",
            "positive": "happy/positive",
            "joy": "happy/positive",
            "grateful": "happy/positive",
            "blessed": "happy/positive",
            "amazing": "happy/positive",
            "great": "happy/positive",
            "excited": "excited/energetic",
            "energetic": "excited/energetic",
            "anxious": "stressed/anxious",
            "anxiety": "stressed/anxious",
            "stressed": "stressed/anxious",
            "panic": "stressed/anxious",
            "worried": "stressed/anxious",
            "depress": "depressed/sad",
            "depressed": "depressed/sad",
            "sad": "depressed/sad",
            "hopeless": "depressed/sad",
            "angry": "angry/frustrated",
            "frustrated": "angry/frustrated",
            "frustration": "angry/frustrated",
            "irritated": "angry/frustrated",
            "neutral": "neutral/calm",
            "calm": "neutral/calm",
            "confused": "confused/uncertain",
            "uncertain": "confused/uncertain",
            "unsure": "confused/uncertain",
        }

        # exact token or substring check
        for k, v in mapping.items():
            if k in p:
                return v

        # phrase-based overrides
        phrase_map = {
            "life feels amazing": "happy/positive",
            "i feel amazing": "happy/positive",
            "i feel great": "happy/positive",
            "i feel good": "happy/positive",
            "i can't calm": "stressed/anxious",
            "i'm overwhelmed": "stressed/anxious",
            "i am overwhelmed": "stressed/anxious",
            "i'm hopeless": "depressed/sad",
            "i don't know what to do": "confused/uncertain",
        }
        for phrase, label in phrase_map.items():
            if phrase in p:
                return label

        return None

    def heuristic_predict(self, text: str) -> Dict[str, float]:
        """
        Keyword + phrase-based heuristic predictor.
        Priority: specific/intense categories first (depression/anxiety/anger),
        then positive/excited, then confusion, then neutral fallback.
        """

        t = (text or "").lower().strip()

        # phrase checks (exact-ish)
        phrases = {
            "life feels amazing": ("happy/positive", 0.95),
            "i feel amazing": ("happy/positive", 0.95),
            "i feel great": ("happy/positive", 0.92),
            "i feel good": ("happy/positive", 0.9),
            "i feel hopeless": ("depressed/sad", 0.95),
            "i can't calm": ("stressed/anxious", 0.95),
            "i'm overwhelmed": ("stressed/anxious", 0.93),
            "i am overwhelmed": ("stressed/anxious", 0.93),
            "i don't know what to do": ("confused/uncertain", 0.85),
        }
        for phrase, (label, conf) in phrases.items():
            if phrase in t:
                return {"prediction": label, "confidence": conf}

        # keyword checks: (keywords list, label, confidence)
        checks = [
            (["hopeless", "depress", "sad", "cry", "crying", "empty", "lonely", "worthless", "numb", "low energy"], "depressed/sad", 0.9),
            (["panic attack", "panic", "anxiety", "anxious", "worried", "worry", "nervous", "racing", "heart racing", "can't calm", "overwhelmed", "overwhelming"], "stressed/anxious", 0.92),
            (["angry", "furious", "annoyed", "irritated", "frustrat", "mad", "fed up", "rage", "hate this", "ridiculous"], "angry/frustrated", 0.88),
            (["excited", "can't wait", "eager", "energ", "enthusiastic", "thrilled", "pumped", "hyped"], "excited/energetic", 0.9),
            (["happy", "joy", "smile", "smiling", "amazing", "best", "great", "wonderful", "perfect", "success", "achievement", "blessed", "grateful"], "happy/positive", 0.92),
            (["stress", "stressed", "deadline", "pressure", "burned out", "burnout", "stretched thin", "tense"], "stressed/anxious", 0.85),
            (["not sure", "unsure", "confused", "confus", "uncertain", "don't know", "what should", "should i", "can't decide", "mixed feelings", "need clarity"], "confused/uncertain", 0.78),
            (["fine", "okay", "ok", "normal day", "routine", "chill", "calm", "neutral", "just here", "doing ok"], "neutral/calm", 0.75),
        ]

        # search for best match by priority/confidence
        best_label = None
        best_conf = 0.0
        for keywords, label, conf in checks:
            for kw in keywords:
                if kw in t:
                    if conf > best_conf:
                        best_conf = conf
                        best_label = label
                    break

        if best_label:
            return {"prediction": best_label, "confidence": round(best_conf, 2)}

        # Final fallback: neutral (prefer neutral over 'confused' to avoid false positives)
        return {"prediction": "neutral/calm", "confidence": 0.7}

    def predict(self, message: str) -> Dict[str, float]:
        """
        Main prediction method: try Groq LLM first with a schema,
        then fallback to heuristic if LLM is unavailable or returns invalid output.
        """
        # quick heuristic guard for very short messages
        if not message or len(message.strip()) <= 2:
            return {"prediction": "neutral/calm", "confidence": 0.7}

        prompt = self._build_prompt(message)

        # Groq call with minimal retry
        raw = None
        parsed = None
        for attempt in range(2):  # 1 retry
            try:
                # Request the model to return a JSON object; provide a schema too
                response = self.client.chat.completions.create(
                    model="llama-3.1-8b-instant",
                    messages=[{"role": "user", "content": prompt}],
                    temperature=0.25,
                    max_tokens=120,
                    # schema hint; some SDKs accept this style - helps nudge model output
                    response_format={
                        "type": "json_object",
                        "schema": {
                            "type": "object",
                            "properties": {
                                "prediction": {"type": "string"},
                                "confidence": {"type": "number"}
                            },
                            "required": ["prediction", "confidence"]
                        }
                    }
                )

                # extract text safely
                raw = getattr(response.choices[0].message, "content", None) or str(response.choices[0])
                if not raw:
                    raw = str(response)
                parsed = self._safe_parse_json(raw)
                if parsed:
                    break
                else:
                    # If not parsed, wait briefly and retry once
                    time.sleep(0.3)
            except Exception as e:
                # log and break to fallback
                print(f"[Groq] attempt {attempt + 1} error: {e}")
                raw = None
                parsed = None
                time.sleep(0.2)
                continue

        # If Groq produced a valid JSON parse, use it
        if parsed:
            pred_raw = parsed.get("prediction")
            conf_raw = parsed.get("confidence", 0.7)
            normalized = self.normalize_prediction(pred_raw) or self.normalize_prediction(str(pred_raw or ""))
            if normalized:
                try:
                    conf = float(conf_raw)
                    conf = max(0.7, min(conf, 1.0))
                except Exception:
                    conf = 0.85
                return {"prediction": normalized, "confidence": round(conf, 2)}
            else:
                # If the model returned an unexpected label, fall back to heuristic
                print(f"[Groq] Unrecognized label from model: {pred_raw}; using heuristic fallback.")
                return self.heuristic_predict(message)

        # If parsing failed or Groq failed, fallback to heuristic
        if raw:
            print(f"[Groq] Raw response (unparseable): {raw[:400]}...")
        else:
            print("[Groq] No raw response; using heuristic fallback.")
        return self.heuristic_predict(message)


# --------------- Remaining system (unchanged logic, lightly cleaned) ---------------

def analyze_user_mental_state(user_id: str) -> Optional[Dict]:
    """Analyze user's mental state using Groq API (with heuristic fallback)."""
    predictor = GroqMentalStatePredictor()

    # Get user messages from Supabase
    try:
        response = supabase.table("messages").select("*").eq("user_id", user_id).execute()
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
        print(f"{i}. [{timestamp}] {msg.get('message', '')}")

    state_counts = defaultdict(int)
    confidence_sum = 0.0
    recent_messages = messages[-20:]  # last 20 messages for analysis

    for i, msg in enumerate(recent_messages, 1):
        text = msg.get("message", "") if isinstance(msg, dict) else str(msg)
        result = predictor.predict(text)
        state_counts[result["prediction"]] += 1
        confidence_sum += float(result["confidence"])
        print(f"Message {i}: {result['prediction']} (confidence: {result['confidence']:.2f})")

    total_messages = len(recent_messages)
    avg_confidence = (confidence_sum / total_messages) if total_messages > 0 else 0.0

    dominant_state = None
    if total_messages > 0:
        dominant_state = max(state_counts, key=state_counts.get)
        # require at least 25% of messages to be in one state to consider it dominant
        if state_counts[dominant_state] / total_messages < 0.25:
            dominant_state = "mixed/no_clear_pattern"

    report = {
        "user_id": user_id,
        "total_messages_analyzed": total_messages,
        "dominant_state": dominant_state or "mixed/no_clear_pattern",
        "confidence": round(avg_confidence, 2),
        "state_distribution": dict(state_counts),
    }

    print("\n🧠 Mental State Analysis Report")
    print(f"👤 User: {user_id}")
    print(f"🔍 Messages Analyzed: {report['total_messages_analyzed']}")
    print(f"📊 State Distribution: {report['state_distribution']}")
    print(f"🎯 Dominant State: {report['dominant_state'].upper()} ({report['confidence']:.0%} confidence)")

    # Save report to Supabase
    try:
        supabase.table("mental_state_reports").insert({
            "user_id": user_id,
            "report": json.dumps(report),
            "dominant_state": report["dominant_state"],
            "confidence": report["confidence"],
            "created_at": datetime.now().isoformat()
        }).execute()
        print("✅ Report saved to Supabase")
    except Exception as e:
        print(f"❌ Error saving report: {e}")

    return report


# The rest of your helper functions are kept intact, with minor defensive checks

def get_user_dominant_state(user_id):
    try:
        response = (
            supabase.table("mental_state_reports")
            .select("dominant_state")
            .eq("user_id", user_id)
            .order("created_at", desc=True)
            .limit(1)
            .execute()
        )
        return response.data[0]["dominant_state"] if response.data else None
    except Exception as e:
        print(f"Error fetching user state: {e}")
        return None


def get_all_doctors():
    try:
        response = supabase.table("doctors").select("*").execute()
        return response.data if response.data else []
    except Exception as e:
        print(f"Error fetching doctors: {e}")
        return []


def get_doctors_by_dominant_state(dominant_state):
    try:
        response = supabase.table("doctors").select("*").eq("dominant_state", dominant_state).execute()
        if response.data:
            return response.data
        response = supabase.table("doctors").select("*").eq("dominant_state", "General").execute()
        return response.data if response.data else []
    except Exception as e:
        print(f"Error fetching doctors by dominant state: {e}")
        return []


def is_doctor_already_assigned(doctor_id):
    try:
        response = supabase.table("recommended_doctor").select("doctor_id").eq("doctor_id", doctor_id).execute()
        return len(response.data) > 0
    except Exception as e:
        print(f"Error checking doctor assignment: {e}")
        return False


def store_recommended_doctor(user_id, doctor_id):
    try:
        response = supabase.table("recommended_doctor").insert({
            "user_id": user_id,
            "doctor_id": doctor_id
        }).execute()
        print(f"\n💾 Recommended doctor stored successfully for user {user_id}")
        return response.data
    except Exception as e:
        print(f"Error storing recommended doctor: {e}")
        return None


def assign_best_available_doctor(user_id, matching_doctors):
    try:
        existing = (
            supabase.table("recommended_doctor")
            .select("doctor_id")
            .eq("user_id", user_id)
            .execute()
        )
        if existing.data:
            doctor_id = existing.data[0]["doctor_id"]
            doctor = next((d for d in matching_doctors if d.get("id") == doctor_id or d.get("id") == str(doctor_id)), None)
            if doctor:
                return doctor

        sorted_doctors = sorted(matching_doctors, key=lambda x: 0 if x.get("dominant_state") != "General" else 1)
        for doctor in sorted_doctors:
            if not is_doctor_already_assigned(doctor.get("id")):
                result = store_recommended_doctor(user_id, doctor.get("id"))
                if result:
                    print(f"\n✅ Assigned Dr. {doctor.get('name')} to user {user_id}")
                    return doctor
        print(f"\n❌ No available doctors found for user {user_id}")
        return None
    except Exception as e:
        print(f"Error assigning doctor: {e}")
        return None


def display_doctors(doctors, title="ALL DOCTORS"):
    print(f"\n{title}")
    print("=" * 70)
    if not doctors:
        print("No doctors found.")
        return
    for i, doctor in enumerate(doctors, 1):
        print(f"\n{i}. Dr. {doctor.get('name', 'N/A')}")
        print(f"   Email: {doctor.get('email', 'N/A')}")
        print(f"   Phone: {doctor.get('phone', 'N/A')}")
        print(f"   Category: {doctor.get('category', 'N/A')}")
        print(f"   Specializes in: {doctor.get('dominant_state', 'General')}")
        print("-" * 50)


def get_entertainments_by_dominant_state(dominant_state):
    try:
        response = supabase.table('entertainments') \
            .select('id, title, type, dominant_state, cover_img_url, description, media_file_url') \
            .eq('dominant_state', dominant_state) \
            .execute()
        return response.data if response.data else []
    except Exception as e:
        print(f"Error fetching entertainments: {e}")
        return []


def store_recommended_entertainments(user_id, entertainments, dominant_state):
    recommendations_stored = 0
    for entertainment in entertainments:
        try:
            recommendation_data = {
                'id': str(uuid.uuid4()),
                'user_id': user_id,
                'entertainment_id': entertainment['id'],
                'recommended_at': datetime.now().isoformat(),
                'matched_state': dominant_state
            }
            supabase.table('recommended_entertainments').insert(recommendation_data).execute()
            recommendations_stored += 1
            print(f"     ✅ Stored {entertainment.get('title', 'Untitled')} recommendation")
        except Exception as insert_error:
            print(f"     ❌ Failed to store {entertainment.get('title', 'Untitled')} recommendation: {insert_error}")
    return recommendations_stored


def display_entertainments(entertainments, title="RECOMMENDED ENTERTAINMENTS"):
    print(f"\n{title}")
    print("=" * 70)
    if not entertainments:
        print("No entertainments found.")
        return
    for i, entertainment in enumerate(entertainments, 1):
        print(f"\n{i}. {entertainment.get('title', 'N/A')}")
        print(f"   Type: {entertainment.get('type', 'N/A')}")
        print(f"   Matches state: {entertainment.get('dominant_state', 'N/A')}")
        print("-" * 50)


def display_stored_recommendations(user_id):
    try:
        response = supabase.table('recommended_entertainments') \
            .select(''' id, user_id, entertainment_id, recommended_at, matched_state, entertainments!inner(title, type) ''') \
            .eq('user_id', user_id) \
            .order('recommended_at', desc=True) \
            .execute()
        if response.data:
            print(f"\n📋 Stored Entertainment Recommendations for User {user_id}:")
            print("=" * 70)
            for i, rec in enumerate(response.data, 1):
                ent = rec.get('entertainments') or {}
                print(f"{i}. Entertainment: {ent.get('title', 'Unknown')}")
                print(f"   Type: {ent.get('type', 'Unknown')}")
                print(f"   Recommended at: {rec.get('recommended_at')}")
                print(f"   Matched State: {rec.get('matched_state')}")
                print()
        else:
            print(f"\nNo stored entertainment recommendations found for user {user_id}")
    except Exception as e:
        print(f"Error fetching stored recommendations: {e}")


def get_all_recommendations(user_id: str) -> Dict:
    dominant_state = get_user_dominant_state(user_id)
    if not dominant_state:
        return {"doctors": [], "entertainments": []}
    doctors = get_doctors_by_dominant_state(dominant_state)
    entertainments = get_entertainments_by_dominant_state(dominant_state)
    if entertainments:
        store_recommended_entertainments(user_id, entertainments, dominant_state)
    assigned_doctor = None
    if doctors:
        assigned_doctor_obj = assign_best_available_doctor(user_id, doctors)
        if assigned_doctor_obj:
            assigned_doctor = [assigned_doctor_obj]
    return {"doctors": assigned_doctor if assigned_doctor else [], "entertainments": entertainments}


def recommend_doctors(user_id, dominant_state):
    print(f"\n=== DOCTOR RECOMMENDATION ===")
    if dominant_state:
        print(f"🧠 User's dominant mental state: {dominant_state.upper()}")
        matching_doctors = get_doctors_by_dominant_state(dominant_state)
        if matching_doctors:
            assigned_doctor = assign_best_available_doctor(user_id, matching_doctors)
            if assigned_doctor:
                display_doctors([assigned_doctor], f"ASSIGNED DOCTOR FOR {dominant_state.upper()}")
            else:
                print(f"\n⚠️ No available doctors specialize in '{dominant_state}' (all assigned).")
                all_doctors = get_all_doctors()
                display_doctors(all_doctors, "ALL AVAILABLE DOCTORS")
        else:
            print(f"\n⚠️ No doctors specialize in '{dominant_state}'")
            all_doctors = get_all_doctors()
            display_doctors(all_doctors, "ALL AVAILABLE DOCTORS")
    else:
        print(f"\n❌ No mental state reports found for user {user_id}.")
        all_doctors = get_all_doctors()
        display_doctors(all_doctors, "ALL AVAILABLE DOCTORS")


def recommend_entertainments(user_id, dominant_state):
    print(f"\n=== ENTERTAINMENT RECOMMENDATION ===")
    if dominant_state:
        print(f"🧠 User's dominant mental state: {dominant_state.upper()}")
        print(f"\n🔍 Searching for entertainments matching '{dominant_state}' state...")
        matching_entertainments = get_entertainments_by_dominant_state(dominant_state)
        if matching_entertainments:
            print(f"\n🎉 Found {len(matching_entertainments)} entertainment(s) matching your dominant state:")
            display_entertainments(matching_entertainments)
            stored_count = store_recommended_entertainments(user_id, matching_entertainments, dominant_state)
            print(f"\n📊 Successfully stored {stored_count} recommendation(s) in 'recommended_entertainments' table!")
            display_stored_recommendations(user_id)
        else:
            print(f"\n❌ No entertainments found matching the '{dominant_state}' state.")
    else:
        print(f"\n❌ No mental state reports found for user: {user_id}")


def main(user_id: Optional[str] = None) -> Optional[Dict]:
    print("=== COMBINED RECOMMENDATION SYSTEM ===")
    if user_id is None:
        user_id = input("Please enter the user ID: ").strip()
    if not user_id:
        print("User ID cannot be empty.")
        return None
    report = analyze_user_mental_state(user_id)
    if not report:
        print(f"❌ Could not analyze mental state for user {user_id}")
        return None
    dominant_state = report["dominant_state"]
    recommend_doctors(user_id, dominant_state)
    recommend_entertainments(user_id, dominant_state)
    return {"mental_state": report, "dominant_state": dominant_state}


if __name__ == "__main__":
    main()
