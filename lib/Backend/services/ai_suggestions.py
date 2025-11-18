import random
from supabase import create_client, Client
from datetime import datetime
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Optional
from config.settings import SUPABASE_URL, SUPABASE_KEY
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create FastAPI router
router = APIRouter(prefix="/ai-suggestions", tags=["AI Suggestions"])

# Pydantic models for request/response validation
class SuggestionResponse(BaseModel):
    success: bool
    user_id: Optional[str] = None
    dominant_state: Optional[str] = None
    suggestions_count: Optional[int] = None
    storage_success: Optional[bool] = None
    suggestions: Optional[List[dict]] = None
    message: Optional[str] = None
    
    class Config:
        extra = "allow"  # Allow extra fields that might come from results

class SuggestionManager:
    def __init__(self):
        # Get Supabase credentials from settings
        self.SUPABASE_URL = SUPABASE_URL
        self.SUPABASE_KEY = SUPABASE_KEY
        
        self.supabase = create_client(self.SUPABASE_URL, self.SUPABASE_KEY)
    
    def fetch_user_dominant_state(self, user_id):
        """Fetch user's dominant state from mental_state_reports table"""
        try:
            logger.info(f"Fetching dominant state for user: {user_id}")
            
            # Get the most recent mental state report for the user
            response = self.supabase.table("mental_state_reports")\
                .select("dominant_state")\
                .eq("user_id", user_id)\
                .order("created_at", desc=True)\
                .limit(1)\
                .execute()
            
            if response.data and len(response.data) > 0:
                state = response.data[0].get("dominant_state")
                logger.info(f"Found dominant state: {state} for user {user_id}")
                return state
            else:
                logger.warning(f"No mental state reports found for user: {user_id}")
                return None
                
        except Exception as error:
            logger.error(f"Error fetching dominant state for user {user_id}: {error}", exc_info=True)
            return None
    
    def fetch_matching_suggestions(self, dominant_state):
        """Fetch and randomly select 5 suggestions based on category"""
        try:
            logger.info(f"Searching suggestions for state: {dominant_state}")
            
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
            logger.info(f"Mapped state '{dominant_state}' to category: {category}")
            
            response = self.supabase.table("suggestions")\
                .select("id, logo, suggestion, description, category")\
                .eq("category", category)\
                .execute()
            
            all_suggestions = response.data if response.data else []
            
            if not all_suggestions:
                logger.warning(f"No suggestions found for category: {category}")
                return []
            
            logger.info(f"Found {len(all_suggestions)} total suggestions")
            
            # Select 5 random suggestions
            if len(all_suggestions) <= 5:
                selected_suggestions = all_suggestions
            else:
                selected_suggestions = random.sample(all_suggestions, 5)
            
            logger.info(f"Selected {len(selected_suggestions)} suggestions")
            return selected_suggestions
            
        except Exception as error:
            logger.error(f"Error fetching suggestions for state {dominant_state}: {error}", exc_info=True)
            return []
    
    def delete_existing_recommendations(self, user_id):
        """Delete all existing recommendations for a user"""
        try:
            logger.info(f"Deleting existing recommendations for user: {user_id}")
            
            response = self.supabase.table("recommended_suggestions")\
                .delete()\
                .eq("user_id", user_id)\
                .execute()
            
            logger.info(f"Successfully deleted existing recommendations")
            return True
            
        except Exception as error:
            logger.error(f"Error deleting recommendations for user {user_id}: {error}", exc_info=True)
            return False
    
    def store_recommended_suggestions(self, user_id, dominant_state, suggestions):
        """Store the recommended suggestions in the database"""
        try:
            logger.info(f"Storing {len(suggestions)} recommendations for user: {user_id}")
            
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
                logger.info(f"Successfully stored {len(response.data)} recommendations")
                return True
            else:
                logger.warning("Failed to store recommendations")
                return False
                
        except Exception as error:
            logger.error(f"Error storing recommendations for user {user_id}: {error}", exc_info=True)
            return False
    
    def get_suggestions_for_user(self, user_id):
        """Main method to get suggestions for a user"""
        logger.info(f"Starting suggestion process for user: {user_id}")
        
        try:
            # Step 1: Get user's dominant state from mental_state_reports
            dominant_state = self.fetch_user_dominant_state(user_id)
            
            if not dominant_state:
                logger.warning(f"No dominant state found for user {user_id}")
                return {
                    "success": False,
                    "user_id": user_id,
                    "message": "Could not find user dominant state in mental state reports"
                }
            
            # Step 2: Get matching suggestions
            suggestions = self.fetch_matching_suggestions(dominant_state)
            
            if not suggestions:
                logger.warning(f"No suggestions found for state {dominant_state}")
                return {
                    "success": False,
                    "user_id": user_id,
                    "dominant_state": dominant_state,
                    "message": f"No suggestions found for dominant state: {dominant_state}"
                }
            
            # Step 3: Delete existing recommendations
            delete_success = self.delete_existing_recommendations(user_id)
            
            if not delete_success:
                logger.warning(f"Failed to clear existing recommendations for user {user_id}")
                return {
                    "success": False,
                    "user_id": user_id,
                    "dominant_state": dominant_state,
                    "message": "Failed to clear existing recommendations"
                }
            
            # Step 4: Store new recommendations in database
            storage_success = self.store_recommended_suggestions(user_id, dominant_state, suggestions)
            
            # Step 5: Return formatted results
            result = {
                "success": True,
                "user_id": user_id,
                "dominant_state": dominant_state,
                "suggestions_count": len(suggestions),
                "storage_success": storage_success,
                "suggestions": suggestions
            }
            logger.info(f"Successfully processed suggestions for user {user_id}")
            return result
            
        except Exception as e:
            logger.error(f"Error in get_suggestions_for_user for user {user_id}: {e}", exc_info=True)
            return {
                "success": False,
                "user_id": user_id,
                "message": f"Error processing suggestions: {str(e)}"
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

# Initialize the SuggestionManager instance
try:
    suggestion_manager = SuggestionManager()
    logger.info("✅ SuggestionManager initialized successfully")
except Exception as e:
    logger.error(f"❌ Error initializing SuggestionManager: {e}")
    suggestion_manager = None

@router.get("/suggestions/{user_id}", response_model=SuggestionResponse)
async def get_suggestions(user_id: str):
    """
    Get AI suggestions for a specific user based on their mental state.
    """
    try:
        if not user_id or not user_id.strip():
            logger.error("Empty user_id provided")
            raise HTTPException(status_code=400, detail="user_id cannot be empty")
        
        if suggestion_manager is None:
            logger.error("SuggestionManager not initialized")
            raise HTTPException(status_code=500, detail="Suggestion service not available")
        
        logger.info(f"Processing suggestion request for user: {user_id}")
        result = suggestion_manager.get_suggestions_for_user(user_id)
        logger.info(f"Suggestion request result: {result.get('success')}")
        return result
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in get_suggestions endpoint: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Error processing suggestions: {str(e)}")

# Keep the main function for testing purposes
if __name__ == "__main__":
    main()