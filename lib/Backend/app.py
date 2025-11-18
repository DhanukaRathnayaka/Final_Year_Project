from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from services.chatbot_service import router as chatbot_router
# Import the suggestions router and include it so /generate_suggestions is available
from services import suggestion_generator
import sys
import os
# Add the backend directory to the Python path
sys.path.append(os.path.dirname(__file__))
from services.ai_suggestions import router as ai_suggestions_router
from services.recommendations import GroqMentalStatePredictor
from services.exercises import router as exercises_router
from pydantic import BaseModel
import logging
from supabase import create_client, Client
from config.settings import SUPABASE_URL, SUPABASE_KEY
from typing import Optional, List
from datetime import datetime, timedelta
import uuid

# Fix encoding issues on Windows
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')
if hasattr(sys.stderr, 'reconfigure'):
    sys.stderr.reconfigure(encoding='utf-8')

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize Supabase client
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# Create FastAPI app
app = FastAPI(title="SafeSpace API")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include the chatbot router with prefix
app.include_router(chatbot_router, prefix="/api", tags=["chatbot"])
# Include the suggestion generator router at root so endpoint is /generate_suggestions
app.include_router(suggestion_generator.router)
# Include the AI suggestions router
app.include_router(ai_suggestions_router)
# Include the exercises router
app.include_router(exercises_router)

# Define request models
class UserRequest(BaseModel):
    user_id: str

class PredictionRequest(BaseModel):
    message: str

@app.get("/")
async def root():
    return {
        "message": "SafeSpace API is running",
        "endpoints": {
            "chatbot": "/api/chat",
            "status": "/",
            "entertainment": "/recommend_entertainment"
        }
    }

@app.post("/api/predict-mental-state")
async def predict_mental_state(req: PredictionRequest):
    """Predict mental state from a message using Groq API with fallback heuristic"""
    try:
        predictor = GroqMentalStatePredictor()
        result = predictor.predict(req.message)
        
        return {
            "prediction": result["prediction"],
            "confidence": result["confidence"],
            "message": req.message
        }
    except Exception as e:
        logger.error(f"Error predicting mental state: {str(e)}")
        # Return a safe fallback
        return {
            "prediction": "neutral/calm",
            "confidence": 0.5,
            "message": req.message,
            "error": str(e)
        }

def get_user_dominant_state(user_id: str) -> Optional[str]:
    """Get the user's most recent dominant mental state"""
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
        logger.error(f"Error getting user state: {str(e)}")
        return None

def get_doctors_by_dominant_state(dominant_state: str) -> list:
    """Get doctors that can handle a specific mental state"""
    try:
        # First try to get doctors specifically matching this state
        response = (
            supabase.table("doctors")
            .select("*")
            .eq("dominant_state", dominant_state)
            .execute()
        )
        
        matching_doctors = response.data if response.data else []
        logger.info(f"Found {len(matching_doctors)} doctors matching state {dominant_state}")
        
        if not matching_doctors:
            # If no specific matches, get doctors who can handle any state
            response = (
                supabase.table("doctors")
                .select("*")
                .is_("dominant_state", "null")
                .execute()
            )
            matching_doctors = response.data if response.data else []
            logger.info(f"Found {len(matching_doctors)} general doctors")
            
        return matching_doctors
    except Exception as e:
        logger.error(f"Error getting doctors: {str(e)}")
        return []

def is_doctor_already_assigned(doctor_id: str) -> bool:
    """Check if a doctor is already assigned to someone"""
    try:
        response = (
            supabase.table("recommended_doctor")
            .select("doctor_id")
            .eq("doctor_id", doctor_id)
            .execute()
        )
        
        logger.info(f"Checking assignment for doctor {doctor_id}: {len(response.data)} assignments found")
        return len(response.data) > 0
    except Exception as e:
        logger.error(f"Error checking doctor assignment: {str(e)}")
        return False  # Assume not assigned in case of error to allow assignment

def store_recommended_doctor(user_id: str, doctor_id: str) -> Optional[dict]:
    """Store a doctor recommendation for a user"""
    try:
        response = supabase.table("recommended_doctor").insert({
            "user_id": user_id,
            "doctor_id": doctor_id
        }).execute()
        return response.data[0] if response.data else None
    except Exception as e:
        logger.error(f"Error storing doctor recommendation: {str(e)}")
        return None

@app.get("/recommend_entertainment/api/suggestions/{user_id}")
async def recommend_entertainment(user_id: str) -> dict:
    """Get entertainment recommendations for a user based on their mental state"""
    try:
        # Import the recommendation function from recommendations service
        from services.recommendations import get_all_recommendations
        
        # Get all recommendations using the existing function
        recommendations = get_all_recommendations(user_id)
        
        if not recommendations or not recommendations.get("entertainments"):
            # If no recommendations, try to generate them
            # Fetch user's dominant state
            response = (
                supabase.table('mental_state_reports')
                .select('dominant_state, created_at')
                .eq('user_id', user_id)
                .order('created_at', desc=True)
                .limit(1)
                .execute()
            )
            
            if not response.data:
                raise HTTPException(
                    status_code=404,
                    detail="No mental state report found for this user"
                )

            report = response.data[0]
            user_dominant_state = report['dominant_state']
            
            # Fetch entertainments with matching dominant state
            entertainment_response = (
                supabase.table('entertainments')
                .select('id, title, type, dominant_state, cover_img_url, description, media_file_url')
                .eq('dominant_state', user_dominant_state)
                .execute()
            )
            
            if not entertainment_response.data:
                return {
                    "success": True,
                    "recommendations": [],
                    "message": f"No entertainments found matching the '{user_dominant_state}' state."
                }
                
            # Store recommendations and prepare response
            recommendations = []
            for entertainment in entertainment_response.data:
                try:
                    recommendation_data = {
                        'id': str(uuid.uuid4()),
                        'user_id': user_id,
                        'entertainment_id': entertainment['id'],
                        'recommended_at': datetime.now().isoformat(),
                        'matched_state': user_dominant_state
                    }
                    
                    # Store the recommendation
                    supabase.table('recommended_entertainments').insert(recommendation_data).execute()
                    
                    # Add to return list with additional details
                    recommendations.append({
                        **entertainment,
                        'recommended_at': recommendation_data['recommended_at'],
                        'matched_state': user_dominant_state
                    })
                    
                except Exception as insert_error:
                    logger.error(f"Failed to store recommendation: {insert_error}")
                    continue
            
            return {
                "success": True,
                "recommendations": recommendations,
                "dominant_state": user_dominant_state
            }
        else:
            # Return the recommendations from get_all_recommendations
            return {
                "success": True,
                "recommendations": recommendations["entertainments"]
            }
        
    except HTTPException as he:
        raise he
    except Exception as e:
        logger.error(f"Error in recommend_entertainment endpoint: {e}")
        raise HTTPException(
            status_code=500,
            detail=str(e)
        )

def assign_best_available_doctor(user_id: str, matching_doctors: list) -> Optional[dict]:
    """Find and assign the best available doctor from a list"""
    logger.info(f"Attempting to assign doctor from {len(matching_doctors)} matching doctors")
    
    if not matching_doctors:
        logger.warning("No matching doctors available to assign")
        return None
        
    for doctor in matching_doctors:
        doctor_id = doctor.get("id")
        if not doctor_id:
            logger.warning(f"Doctor record missing ID: {doctor}")
            continue
            
        logger.info(f"Checking availability of doctor {doctor_id}")
        if not is_doctor_already_assigned(doctor_id):
            logger.info(f"Doctor {doctor_id} is available, attempting to store recommendation")
            if store_recommended_doctor(user_id, doctor_id):
                logger.info(f"Successfully assigned doctor {doctor_id} to user {user_id}")
                return doctor
            else:
                logger.error(f"Failed to store recommendation for doctor {doctor_id}")
        else:
            logger.info(f"Doctor {doctor_id} is already assigned")
            
    logger.warning("No available doctors found after checking all matches")
    return None

@app.get("/recommendations")
async def get_recommendations(user_id: str):
    """Get personalized recommendations for a user based on their mental state"""
    try:
        # Import the recommendation function from recommendations service
        from services.recommendations import get_all_recommendations
        
        # Get all recommendations
        recommendations = get_all_recommendations(user_id)
        
        return {
            "success": True,
            "recommendations": recommendations
        }
    except Exception as e:
        logger.error(f"Error getting recommendations: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error getting recommendations: {str(e)}"
        )
@app.get("/api/suggestions/{user_id}")
async def get_suggestions(user_id: str):
    """Get personalized suggestions for a user based on their mental state"""
    try:
        # Import the recommendation function from recommendations service
        from services.recommendations import get_all_recommendations
        
        # Get all recommendations
        recommendations = get_all_recommendations(user_id)
        
        return {
            "doctors": recommendations["doctors"],
            "entertainments": recommendations["entertainments"]
        }
    except Exception as e:
        logger.error(f"Error getting suggestions: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error getting suggestions: {str(e)}"
        )

@app.post("/recommend")
async def recommend_doctor(req: UserRequest):
    """Recommend a doctor for a user based on their mental state"""
    try:
        logger.info("====== New Doctor Recommendation Request ======")
        logger.info(f"User ID: {req.user_id}")
        logger.info(f"Supabase URL: {SUPABASE_URL}")
        logger.info("Attempting to connect to Supabase...")
        
        # Check if user already has an assigned doctor
        try:
            existing = (
                supabase.table("recommended_doctor")
                .select("doctor_id")
                .eq("user_id", req.user_id)
                .execute()
            )
            
            if existing.data:
                doctor_id = existing.data[0]["doctor_id"]
                doctor = (
                    supabase.table("doctors")
                    .select("*")
                    .eq("id", doctor_id)
                    .execute()
                )
                if doctor.data:
                    logger.info(f"Found existing doctor assignment for user {req.user_id}")
                    return {"assigned_doctor": doctor.data[0]}
        except Exception as e:
            logger.error(f"Error checking existing doctor: {str(e)}")
            # Continue to new assignment if checking existing fails
        
        # Get user's dominant mental state
        dominant_state = get_user_dominant_state(req.user_id)
        if not dominant_state:
            logger.warning(f"No mental state found for user {req.user_id}")
            raise HTTPException(
                status_code=404,
                detail="No mental state report found. Please complete your mental state assessment first."
            )
        
        logger.info(f"User {req.user_id} dominant state: {dominant_state}")
        
        # Get matching doctors
        matching_doctors = get_doctors_by_dominant_state(dominant_state)
        if not matching_doctors:
            logger.warning(f"No doctors found for state: {dominant_state}")
            # Fallback to any available doctor if no specific match
            try:
                matching_doctors = supabase.table("doctors").select("*").execute().data
            except Exception as e:
                logger.error(f"Error getting all doctors: {str(e)}")
                matching_doctors = []
                
            if not matching_doctors:
                raise HTTPException(
                    status_code=404,
                    detail="No doctors available in the system"
                )
        
        # Assign best available doctor
        assigned_doctor = assign_best_available_doctor(req.user_id, matching_doctors)
        if not assigned_doctor:
            raise HTTPException(
                status_code=503,
                detail="All doctors are currently assigned. Please try again later."
            )
        
        logger.info(f"Successfully assigned doctor {assigned_doctor['id']} to user {req.user_id}")
        return {"assigned_doctor": assigned_doctor}
        
    except HTTPException:
        raise
    except Exception as e:
        error_msg = str(e)
        logger.error(f"Error in doctor recommendation: {error_msg}")
        logger.error(f"Type of error: {type(e)}")
        import traceback
        logger.error(f"Stack trace: {traceback.format_exc()}")
        
        # Return a more detailed error message
        raise HTTPException(
            status_code=500,
            detail=f"Server error: {error_msg}"
        )