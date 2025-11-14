import os
import uuid
import groq
import json
from collections import defaultdict
from datetime import datetime
from supabase import create_client, Client
from typing import Dict, List, Optional

# Initialize Groq client
GROQ_API_KEY = os.environ.get("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")

# Initialize Supabase client
supabase_url = os.environ.get("SUPABASE_URL", "https://cpuhivcyhvqayzgdvdaw.supabase.co")
supabase_key = os.environ.get("SUPABASE_KEY", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNwdWhpdmN5aHZxYXl6Z2R2ZGF3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMzNDc4NDgsImV4cCI6MjA2ODkyMzg0OH0.dO22JLQjE7UeQHvQn6mojILNuWi_02MiZ9quz5v8pNk")
supabase = create_client(supabase_url, supabase_key)

# Mental state predictor
class GroqMentalStatePredictor:
    def __init__(self):
        api_key = os.environ.get("GROQ_API_KEY")
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
            "excited/energetic"
        ]

    def predict(self, message: str) -> Dict[str, float]:
        """Predict mental state from a single message using Groq"""
        prompt = f"""
        Analyze the following message and classify the writer's mental state based on these specific emotional indicators:

        happy/positive: expressions of joy, achievement, optimism, satisfaction
        stressed/anxious: mentions of worry, pressure, racing thoughts, deadlines, overwhelm
        depressed/sad: expressions of hopelessness, low energy, loss of interest, emptiness
        angry/frustrated: expressions of anger, irritation, complaints, blame
        neutral/calm: balanced mood, routine activities, no strong emotions
        confused/uncertain: expressions of doubt, unclear thoughts, seeking guidance
        excited/energetic: high energy, enthusiasm, eagerness, motivation, future-focused excitement

        Only respond with ONE of these exact conditions:
        {", ".join(self.mental_conditions)}
        
        Message to analyze: "{message}"
        
        Consider:
        1. Emotional keywords and phrases
        2. Intensity of expression
        3. Context of the message
        4. Energy level expressed
        5. Future vs present orientation
        
        Provide confidence score between 0.7 and 1.0 based on how clearly the message matches the emotional indicators.
        
        Return your response in this exact JSON format:
        {{
            "prediction": "selected_condition",
            "confidence": 0.85
        }}
        """
        def normalize_prediction(pred: str) -> Optional[str]:
            if not pred or not isinstance(pred, str):
                return None
            p = pred.strip().lower()
            # direct match
            if p in self.mental_conditions:
                return p
            # map common variants / keywords to canonical labels
            mapping = {
                "happy": "happy/positive",
                "positive": "happy/positive",
                "joy": "happy/positive",
                "stressed": "stressed/anxious",
                "anxious": "stressed/anxious",
                "anxiety": "stressed/anxious",
                "depressed": "depressed/sad",
                "sad": "depressed/sad",
                "angry": "angry/frustrated",
                "frustrated": "angry/frustrated",
                "frustration": "angry/frustrated",
                "neutral": "neutral/calm",
                "calm": "neutral/calm",
                "confused": "confused/uncertain",
                "uncertain": "confused/uncertain",
                "excited": "excited/energetic",
                "energetic": "excited/energetic",
                "excited/energetic": "excited/energetic",
            }
            # check full token or keyword presence
            for k, v in mapping.items():
                if k in p:
                    return v
            return None

        def heuristic_predict(text: str) -> Dict[str, float]:
            t = (text or "").lower()
            checks = [
                # Prioritize checking for positive emotions first
                (['happy', 'joy', 'smil', 'amazing', 'best', 'excit', 'great', 'wonderful', 'passed', 'distinction', 'achievement', 'success', 'perfect'], 'happy/positive', 0.9),
                (['excite', 'burst', "can't wait", 'eager', 'energ', 'enthusiastic', 'thrilled'], 'excited/energetic', 0.85),
                (['stress', 'overwhelm', 'racing', 'deadline', 'anxious', 'worry', 'panic', 'nervous'], 'stressed/anxious', 0.85),
                (['hopeless', 'depress', 'sad', 'low energy', 'cant find joy', 'empty', "don't see the point"], 'depressed/sad', 0.85),
                (['angry', 'furious', 'fed up', 'ridiculous', 'incompetent', 'annoyed', 'frustrat'], 'angry/frustrated', 0.85),
                (['not sure', 'unsure', 'confus', 'clarif', 'should i', 'what should'], 'confused/uncertain', 0.75),
                (['regular day', 'lunch', 'mild', 'okay', 'ok', 'routine'], 'neutral/calm', 0.75)
            ]
            
            max_confidence = 0
            best_prediction = None
            
            for keywords, label, conf in checks:
                for kw in keywords:
                    if kw in t:
                        if conf > max_confidence:
                            max_confidence = conf
                            best_prediction = label
            
            if best_prediction:
                return {'prediction': best_prediction, 'confidence': max_confidence}
                
            # Only fall back to neutral if no other emotion is detected
            return {'prediction': 'neutral/calm', 'confidence': 0.7}

        try:
            # Print debugging information
            try:
                print(f"\n🔑 Using API key: {self.client.api_key[:8]}...")
            except Exception:
                print("\n🔑 Using API client (api_key unavailable)")

            response = self.client.chat.completions.create(
                model="llama-3.1-8b-instant",
                messages=[{"role": "user", "content": prompt}],
                temperature=0.3,
                max_tokens=100,
                response_format={"type": "json_object"}
            )

            # Log raw API response for debugging
            raw = getattr(response.choices[0].message, 'content', None) or str(response.choices[0])
            print(f"\n📊 Raw Groq API Response:\n{raw}")

            try:
                result = json.loads(raw)
                if not isinstance(result, dict) or "prediction" not in result or "confidence" not in result:
                    raise ValueError("Invalid response format")

                pred_raw = result.get("prediction")
                pred_norm = normalize_prediction(pred_raw)
                if not pred_norm:
                    # try normalizing by cleaning pred_raw
                    if isinstance(pred_raw, str):
                        pred_norm = normalize_prediction(pred_raw.replace('"', '').replace("'", ''))

                if not pred_norm:
                    raise ValueError(f"Invalid prediction: {pred_raw}")

                conf = float(result.get("confidence", 0.7))
                conf = max(0.7, min(conf, 1.0))
                return {"prediction": pred_norm, "confidence": conf}
            except (json.JSONDecodeError, ValueError) as e:
                print(f"Error parsing Groq response: {e}")
                # fallback to local heuristic
                fallback = heuristic_predict(message)
                print(f"Fallback heuristic prediction: {fallback}")
                return fallback
        except Exception as e:
            print(f"Prediction error: {e}")
            # API failed - use heuristic to avoid always returning confused/uncertain
            fallback = heuristic_predict(message)
            print(f"API failure fallback prediction: {fallback}")
            return fallback

def analyze_user_mental_state(user_id: str) -> Optional[Dict]:
    """Analyze user's mental state using Groq API"""
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
        print(f"{i}. [{timestamp}] {msg['message']}")

    state_counts = defaultdict(int)
    confidence_sum = 0
    recent_messages = messages[-20:]  # last 20 messages for analysis

    # Analyze individual messages
    for i, msg in enumerate(recent_messages, 1):
        result = predictor.predict(msg['message'])
        state_counts[result['prediction']] += 1
        confidence_sum += result['confidence']
        # Log per-message predictions
        print(f"Message {i}: {result['prediction']} (confidence: {result['confidence']:.2f})")

    total_messages = len(recent_messages)
    dominant_state = max(state_counts, key=state_counts.get)
    avg_confidence = confidence_sum / total_messages

    if state_counts[dominant_state] / total_messages < 0.25:
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

# Common utility functions
def get_user_dominant_state(user_id):
    """Fetch the most recent dominant_state for a user"""
    try:
        response = (
            supabase.table("mental_state_reports")
            .select("dominant_state")
            .eq("user_id", user_id)
            .order("created_at", desc=True)
            .limit(1)
            .execute()
        )
        return response.data[0]['dominant_state'] if response.data else None
    except Exception as e:
        print(f"Error fetching user state: {e}")
        return None

# Doctor recommendation functions
def get_all_doctors():
    """Fetch all doctors from the database"""
    try:
        response = supabase.table("doctors").select("*").execute()
        return response.data if response.data else []
    except Exception as e:
        print(f"Error fetching doctors: {e}")
        return []

def get_doctors_by_dominant_state(dominant_state):
    """Fetch doctors who have the same dominant_state"""
    try:
        # First try to find doctors specializing in this state
        response = (
            supabase.table("doctors")
            .select("*")
            .eq("dominant_state", dominant_state)
            .execute()
        )
        
        if response.data:
            return response.data
            
        # If no specialists found, get doctors who handle general cases
        response = (
            supabase.table("doctors")
            .select("*")
            .eq("dominant_state", "General")
            .execute()
        )
        
        return response.data if response.data else []
    except Exception as e:
        print(f"Error fetching doctors by dominant state: {e}")
        return []

def is_doctor_already_assigned(doctor_id):
    """Check if the doctor is already assigned to another user"""
    try:
        response = (
            supabase.table("recommended_doctor")
            .select("doctor_id")
            .eq("doctor_id", doctor_id)
            .execute()
        )
        return len(response.data) > 0
    except Exception as e:
        print(f"Error checking doctor assignment: {e}")
        return False

def store_recommended_doctor(user_id, doctor_id):
    """Store the recommended doctor for a user"""
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
    """
    Assign the best available doctor based on specialization and availability.
    """
    try:
        # Check if user already has an assigned doctor
        existing = (
            supabase.table("recommended_doctor")
            .select("doctor_id")
            .eq("user_id", user_id)
            .execute()
        )
        
        if existing.data:
            doctor_id = existing.data[0]["doctor_id"]
            doctor = next((d for d in matching_doctors if d["id"] == doctor_id), None)
            if doctor:
                return doctor
        
        # Sort doctors by specialization (specialists first, then general practitioners)
        sorted_doctors = sorted(
            matching_doctors,
            key=lambda x: 0 if x.get("dominant_state") != "General" else 1
        )
        
        # Try to find an available doctor
        for doctor in sorted_doctors:
            if not is_doctor_already_assigned(doctor["id"]):
                result = store_recommended_doctor(user_id, doctor["id"])
                if result:
                    print(f"\n✅ Assigned Dr. {doctor['name']} to user {user_id}")
                    return doctor
        
        print(f"\n❌ No available doctors found for user {user_id}")
        return None
        
    except Exception as e:
        print(f"Error assigning doctor: {e}")
        return None

def display_doctors(doctors, title="ALL DOCTORS"):
    """Display doctors in a formatted way using the actual table columns"""
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

# Entertainment recommendation functions
def get_entertainments_by_dominant_state(dominant_state):
    """Fetch entertainments that match the dominant state"""
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
    """Store entertainment recommendations for a user"""
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
            
            # Insert into the recommended_entertainments table
            supabase.table('recommended_entertainments') \
                .insert(recommendation_data) \
                .execute()
            
            recommendations_stored += 1
            print(f"     ✅ Stored {entertainment['title']} recommendation")
            
        except Exception as insert_error:
            print(f"     ❌ Failed to store {entertainment['title']} recommendation: {insert_error}")
    
    return recommendations_stored

def display_entertainments(entertainments, title="RECOMMENDED ENTERTAINMENTS"):
    """Display entertainments in a formatted way"""
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
    """Display stored entertainment recommendations for a user"""
    try:
        response = supabase.table('recommended_entertainments') \
            .select('''
                id,
                user_id,
                entertainment_id,
                recommended_at,
                matched_state,
                entertainments!inner(title, type)
            ''') \
            .eq('user_id', user_id) \
            .order('recommended_at', desc=True) \
            .execute()
        
        if response.data:
            print(f"\n📋 Stored Entertainment Recommendations for User {user_id}:")
            print("=" * 70)
            
            for i, rec in enumerate(response.data, 1):
                print(f"{i}. Entertainment: {rec['entertainments']['title']}")
                print(f"   Type: {rec['entertainments']['type']}")
                print(f"   Recommended at: {rec['recommended_at']}")
                print(f"   Matched State: {rec['matched_state']}")
                print()
        else:
            print(f"\nNo stored entertainment recommendations found for user {user_id}")
            
    except Exception as e:
        print(f"Error fetching stored recommendations: {e}")

# Main recommendation system - UPDATED FUNCTION
def get_all_recommendations(user_id: str) -> Dict:
    """
    Get all recommendations for a user based on their mental state.
    Returns a dictionary with doctors and entertainment recommendations.
    Also stores the recommendations in the database.
    """
    # Get user's dominant state
    dominant_state = get_user_dominant_state(user_id)
    
    if not dominant_state:
        # If no dominant state, return empty recommendations
        return {
            "doctors": [],
            "entertainments": []
        }
    
    # Get doctor recommendations
    doctors = get_doctors_by_dominant_state(dominant_state)
    
    # Get entertainment recommendations
    entertainments = get_entertainments_by_dominant_state(dominant_state)
    
    # STORE THE RECOMMENDATIONS IN DATABASE
    if entertainments:
        store_recommended_entertainments(user_id, entertainments, dominant_state)
    
    # For doctors, we need to assign one (not just get the list)
    assigned_doctor = None
    if doctors:
        assigned_doctor_obj = assign_best_available_doctor(user_id, doctors)
        if assigned_doctor_obj:
            assigned_doctor = [assigned_doctor_obj]  # Return as list for consistency
    
    return {
        "doctors": assigned_doctor if assigned_doctor else [],
        "entertainments": entertainments
    }

# CLI functions (for testing)
def recommend_doctors(user_id, dominant_state):
    """Doctor recommendation logic"""
    print(f"\n=== DOCTOR RECOMMENDATION ===")
    
    if dominant_state:
        print(f"🧠 User's dominant mental state: {dominant_state.upper()}")
        
        # Get doctors with matching dominant_state
        matching_doctors = get_doctors_by_dominant_state(dominant_state)
        
        if matching_doctors:
            # Assign best available doctor
            assigned_doctor = assign_best_available_doctor(user_id, matching_doctors)
            
            if assigned_doctor:
                display_doctors([assigned_doctor], f"ASSIGNED DOCTOR FOR {dominant_state.upper()}")
            else:
                print(f"\n⚠️ No available doctors specialize in '{dominant_state}' (all assigned).")
                # Show all doctors as fallback
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
    """Entertainment recommendation logic"""
    print(f"\n=== ENTERTAINMENT RECOMMENDATION ===")
    
    if dominant_state:
        print(f"🧠 User's dominant mental state: {dominant_state.upper()}")
        
        # Fetch entertainments with matching dominant state
        print(f"\n🔍 Searching for entertainments matching '{dominant_state}' state...")
        
        matching_entertainments = get_entertainments_by_dominant_state(dominant_state)
        
        if matching_entertainments:
            print(f"\n🎉 Found {len(matching_entertainments)} entertainment(s) matching your dominant state:")
            display_entertainments(matching_entertainments)
            
            # Store recommendations
            stored_count = store_recommended_entertainments(user_id, matching_entertainments, dominant_state)
            print(f"\n📊 Successfully stored {stored_count} recommendation(s) in 'recommended_entertainments' table!")
            
            # Display stored recommendations
            display_stored_recommendations(user_id)
        else:
            print(f"\n❌ No entertainments found matching the '{dominant_state}' state.")
    else:
        print(f"\n❌ No mental state reports found for user: {user_id}")

def main(user_id: Optional[str] = None) -> Optional[Dict]:
    """
    Main function to run the combined recommendation system.
    Can be run in two modes:
    1. CLI mode (user_id=None): Prompts for user input
    2. Automatic mode (user_id provided): Runs directly with given ID
    
    Returns a dict with mental state analysis and recommendations or None if failed
    """
    print("=== COMBINED RECOMMENDATION SYSTEM ===")
    
    # If no user_id provided, get it from input (CLI mode)
    if user_id is None:
        user_id = input("Please enter the user ID: ").strip()
    
    if not user_id:
        print("User ID cannot be empty.")
        return None
    
    # First run mental state analysis
    report = analyze_user_mental_state(user_id)
    if not report:
        print(f"❌ Could not analyze mental state for user {user_id}")
        return None

    dominant_state = report["dominant_state"]
    
    # Automatically provide both recommendations
    recommend_doctors(user_id, dominant_state)
    recommend_entertainments(user_id, dominant_state)
    
    return {
        "mental_state": report,
        "dominant_state": dominant_state
    }

# Run the program in CLI mode if called directly
if __name__ == "__main__":
    main()