import os
import uuid
import groq
import json
from collections import defaultdict
from datetime import datetime
from supabase import create_client, Client
from typing import Dict, List, Optional

# Initialize Groq client
GROQ_API_KEY = os.environ.get("GROQ_API_KEY", "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")

# Mental state predictor
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

# Initialize Supabase client
supabase_url = os.environ.get("SUPABASE_URL", "https://cpuhivcyhvqayzgdvdaw.supabase.co")
supabase_key = os.environ.get("SUPABASE_KEY", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNwdWhpdmN5aHZxYXl6Z2R2ZGF3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMzNDc4NDgsImV4cCI6MjA2ODkyMzg0OH0.dO22JLQjE7UeQHvQn6mojILNuWi_02MiZ9quz5v8pNk")
supabase = create_client(supabase_url, supabase_key)

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
            .select('id, title, type, dominant_state') \
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

# Main recommendation system
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

def get_all_recommendations(user_id: str) -> Dict:
    """
    Get all recommendations for a user based on their mental state.
    Returns a dictionary with doctors and entertainment recommendations.
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
    
    return {
        "doctors": doctors,
        "entertainments": entertainments
    }

# Run the program in CLI mode if called directly
if __name__ == "__main__":
    main()