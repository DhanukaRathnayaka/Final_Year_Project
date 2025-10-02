import random
from supabase import create_client, Client
from datetime import datetime

class SuggestionManager:
    def __init__(self):
        # Hardcoded Supabase credentials
        self.SUPABASE_URL = "https://cpuhivcyhvqayzgdvdaw.supabase.co"
        self.SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNwdWhpdmN5aHZxYXl6Z2R2ZGF3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMzNDc4NDgsImV4cCI6MjA2ODkyMzg0OH0.dO22JLQjE7UeQHvQn6mojILNuWi_02MiZ9quz5v8pNk"
        
        self.supabase = create_client(self.SUPABASE_URL, self.SUPABASE_KEY)
    
    def fetch_user_dominant_state(self, user_id):
        """Fetch user's dominant state from mental_state_reports table"""
        try:
            print(f"🔍 Fetching dominant state from mental_state_reports...")
            
            # Get the most recent mental state report for the user
            response = self.supabase.table("mental_state_reports")\
                .select("dominant_state")\
                .eq("user_id", user_id)\
                .order("created_at", desc=True)\
                .limit(1)\
                .execute()
            
            if response.data and len(response.data) > 0:
                state = response.data[0].get("dominant_state")
                print(f"✅ Found dominant state: {state}")
                return state
            else:
                print("❌ No mental state reports found for this user")
                return None
                
        except Exception as error:
            print(f"🚨 Error fetching dominant state: {error}")
            return None
    
    def fetch_matching_suggestions(self, dominant_state):
        """Fetch and randomly select 5 suggestions based on category"""
        try:
            print(f"🔍 Searching suggestions for category: {dominant_state}")
            
            # Map dominant_state to your category values
            category_mapping = {
                'happy': 'happy/positive',
                'positive': 'happy/positive',
                'stressed': 'stressed/anxious',
                'anxious': 'stressed/anxious',
                'depressed': 'depressed/sad',
                'sad': 'depressed/sad',
                'angry': 'angry/frustrated',
                'frustrated': 'angry/frustrated',
                'neutral': 'neutral/calm',
                'calm': 'neutral/calm',
                'confused': 'confused/uncertain',
                'uncertain': 'confused/uncertain',
                'excited': 'excited/energetic',
                'energetic': 'excited/energetic'
            }
            
            # Get the corresponding category
            category = category_mapping.get(dominant_state.lower(), dominant_state)
            print(f"🎯 Mapped to category: {category}")
            
            response = self.supabase.table("suggestions")\
                .select("id, logo, suggestion, description, category")\
                .eq("category", category)\
                .execute()
            
            all_suggestions = response.data
            
            if not all_suggestions:
                print(f"❌ No suggestions found for category: {category}")
                return []
            
            print(f"📊 Found {len(all_suggestions)} total suggestions")
            
            # Select 5 random suggestions
            if len(all_suggestions) <= 5:
                selected_suggestions = all_suggestions
            else:
                selected_suggestions = random.sample(all_suggestions, 5)
            
            print(f"🎲 Selected {len(selected_suggestions)} random suggestions")
            return selected_suggestions
            
        except Exception as error:
            print(f"🚨 Error fetching suggestions: {error}")
            return []
    
    def delete_existing_recommendations(self, user_id):
        """Delete all existing recommendations for a user"""
        try:
            print(f"🗑️  Deleting existing recommendations for user {user_id}...")
            
            response = self.supabase.table("recommended_suggestions")\
                .delete()\
                .eq("user_id", user_id)\
                .execute()
            
            print(f"✅ Successfully deleted existing recommendations")
            return True
            
        except Exception as error:
            print(f"🚨 Error deleting existing recommendations: {error}")
            return False
    
    def store_recommended_suggestions(self, user_id, dominant_state, suggestions):
        """Store the recommended suggestions in the database"""
        try:
            print(f"💾 Storing new recommendations in database...")
            
            recommendations_data = []
            for suggestion in suggestions:
                recommendation = {
                    'user_id': user_id,
                    'suggestion_id': suggestion['id'],
                    'dominant_state': dominant_state
                }
                recommendations_data.append(recommendation)
            
            # Insert all recommendations in batch
            response = self.supabase.table("recommended_suggestions")\
                .insert(recommendations_data)\
                .execute()
            
            if response.data:
                print(f"✅ Successfully stored {len(response.data)} new recommendations")
                return True
            else:
                print("❌ Failed to store new recommendations")
                return False
                
        except Exception as error:
            print(f"🚨 Error storing new recommendations: {error}")
            return False
    
    def get_suggestions_for_user(self, user_id):
        """Main method to get suggestions for a user"""
        print(f"\n" + "="*60)
        print(f"🚀 STARTING SUGGESTION PROCESS")
        print("="*60)
        
        # Step 1: Get user's dominant state from mental_state_reports
        dominant_state = self.fetch_user_dominant_state(user_id)
        
        if not dominant_state:
            return {"success": False, "message": "Could not find user dominant state in mental state reports"}
        
        # Step 2: Get matching suggestions
        suggestions = self.fetch_matching_suggestions(dominant_state)
        
        if not suggestions:
            return {"success": False, "message": f"No suggestions found for dominant state: {dominant_state}"}
        
        # Step 3: Delete existing recommendations
        delete_success = self.delete_existing_recommendations(user_id)
        
        if not delete_success:
            return {"success": False, "message": "Failed to clear existing recommendations"}
        
        # Step 4: Store new recommendations in database
        storage_success = self.store_recommended_suggestions(user_id, dominant_state, suggestions)
        
        # Step 5: Return formatted results
        return {
            "success": True,
            "user_id": user_id,
            "dominant_state": dominant_state,
            "suggestions_count": len(suggestions),
            "storage_success": storage_success,
            "suggestions": suggestions
        }

def main():
    manager = SuggestionManager()
    
    while True:
        print("\n" + "👤 USER SUGGESTION SYSTEM ".center(50, "="))
        print("Enter User ID (or 'quit' to exit):")
        user_id = input("User ID: ").strip()
        
        if user_id.lower() == 'quit':
            print("👋 Goodbye!")
            break
            
        if not user_id:
            print("❌ Please enter a valid User ID")
            continue
        
        print("\n⏳ Processing your request...")
        result = manager.get_suggestions_for_user(user_id)
        
        print(f"\n" + "📋 RESULTS ".ljust(60, "="))
        if result["success"]:
            print(f"✅ User: {result['user_id']}")
            print(f"🎯 Dominant State: {result['dominant_state']}")
            print(f"📦 Suggestions Found: {result['suggestions_count']}")
            print(f"🗑️  Old recommendations cleared: ✅ Yes")
            print(f"💾 New recommendations stored: {'✅ Yes' if result.get('storage_success') else '❌ No'}")
            print("\n💡 SUGGESTIONS:")
            for i, suggestion in enumerate(result["suggestions"], 1):
                print(f"   {i}. {suggestion['logo']} {suggestion['suggestion']}")
                print(f"      📝 Description: {suggestion['description']}")
                print(f"      🏷️  Category: {suggestion['category']}")
                print()
        else:
            print(f"❌ {result['message']}")
        print("=" * 60)

if __name__ == "__main__":
    main()