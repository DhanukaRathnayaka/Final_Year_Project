from fastapi import APIRouter, HTTPException, Query
from supabase import create_client, Client
from datetime import datetime, timedelta
from typing import List, Optional
import os
import json
import logging

logger = logging.getLogger(__name__)

# Initialize Supabase from environment variables
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

if not SUPABASE_URL or not SUPABASE_KEY:
    raise ValueError("SUPABASE_URL and SUPABASE_KEY environment variables are required")

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
router = APIRouter(prefix="/exercises", tags=["exercises"])


@router.get("/categories")
async def get_categories():
    """
    Get all unique exercise categories from the exercises table.
    Groups exercises by category_name.
    """
    try:
        response = supabase.table("exercises")\
            .select("category_name, category_image_path")\
            .filter("is_active", "eq", True)\
            .execute()
        
        if not response.data:
            return []
        
        # Group by category
        categories = {}
        for exercise in response.data:
            cat_name = exercise["category_name"]
            if cat_name not in categories:
                categories[cat_name] = {
                    "id": cat_name.lower().replace(" ", "-"),
                    "name": cat_name,
                    "image_path": exercise["category_image_path"],
                    "exercises": []
                }
        
        return list(categories.values())
    except Exception as e:
        logger.error(f"Error fetching categories: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to fetch categories: {str(e)}")


@router.get("/category/{category_id}")
async def get_exercises_by_category(category_id: str):
    """
    Get all exercises for a specific category.
    category_id is converted from kebab-case to Title Case.
    """
    try:
        # Convert category_id from kebab-case to Title Case
        category_name = category_id.replace("-", " ").title()
        
        response = supabase.table("exercises")\
            .select("*")\
            .filter("category_name", "eq", category_name)\
            .filter("is_active", "eq", True)\
            .execute()
        
        if not response.data:
            return []
        
        exercises = []
        for ex in response.data:
            # Parse chat_flow if it's a string
            chat_flow = ex.get("chat_flow", [])
            if isinstance(chat_flow, str):
                try:
                    chat_flow = json.loads(chat_flow)
                except json.JSONDecodeError:
                    chat_flow = []
            
            exercises.append({
                "id": ex["id"],
                "name": ex["exercise_name"],
                "duration": ex["duration"],
                "category": ex["category_name"],
                "category_image_path": ex["category_image_path"],
                "description": ex["exercise_description"],
                "chat_flow": chat_flow
            })
        
        return exercises
    except Exception as e:
        logger.error(f"Error fetching exercises by category: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to fetch exercises: {str(e)}")


@router.get("/{exercise_id}")
async def get_exercise(exercise_id: str):
    """
    Get a single exercise by ID with its full chat flow.
    """
    try:
        response = supabase.table("exercises")\
            .select("*")\
            .eq("id", exercise_id)\
            .execute()
        
        if not response.data:
            raise HTTPException(status_code=404, detail="Exercise not found")
        
        ex = response.data[0]
        
        # Parse chat_flow if it's a string
        chat_flow = ex.get("chat_flow", [])
        if isinstance(chat_flow, str):
            try:
                chat_flow = json.loads(chat_flow)
            except json.JSONDecodeError:
                chat_flow = []
        
        return {
            "id": ex["id"],
            "name": ex["exercise_name"],
            "duration": ex["duration"],
            "category": ex["category_name"],
            "category_image_path": ex["category_image_path"],
            "description": ex["exercise_description"],
            "chat_flow": chat_flow
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching exercise: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to fetch exercise: {str(e)}")


@router.post("/complete")
async def log_completion(completion_data: dict):
    """
    Log an exercise completion for a user.
    Accepts JSON body with: user_id, exercise_id, duration_seconds
    """
    try:
        user_id = completion_data.get("user_id")
        exercise_id = completion_data.get("exercise_id")
        duration_seconds = completion_data.get("duration_seconds", 0)
        
        if not user_id or not exercise_id:
            raise HTTPException(status_code=400, detail="Missing user_id or exercise_id")
        
        # Verify exercise exists
        ex_response = supabase.table("exercises")\
            .select("id")\
            .eq("id", exercise_id)\
            .execute()
        
        if not ex_response.data:
            raise HTTPException(status_code=404, detail="Exercise not found")
        
        # Insert completion record
        supabase.table("exercise_completions").insert({
            "user_id": user_id,
            "exercise_id": exercise_id,
            "duration_seconds": duration_seconds,
            "completed_at": datetime.now().isoformat()
        }).execute()
        
        return {"success": True, "message": "Completion logged successfully"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error logging completion: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to log completion: {str(e)}")


@router.get("/user/{user_id}/stats")
async def get_user_stats(user_id: str):
    """
    Get comprehensive exercise statistics for a user.
    Returns: completed_today, total_duration, weekly_average, streak
    """
    try:
        today = datetime.now().date()
        week_ago = today - timedelta(days=7)
        
        # Get today's completions
        today_response = supabase.table("exercise_completions")\
            .select("duration_seconds")\
            .filter("user_id", "eq", user_id)\
            .gte("completed_at", f"{today}T00:00:00")\
            .execute()
        
        today_data = today_response.data if today_response.data else []
        completed_today = len(today_data)
        total_duration = sum(ex.get("duration_seconds") or 0 for ex in today_data)
        
        # Get weekly data for average
        week_response = supabase.table("exercise_completions")\
            .select("completed_at")\
            .filter("user_id", "eq", user_id)\
            .gte("completed_at", f"{week_ago}T00:00:00")\
            .execute()
        
        week_data = week_response.data if week_response.data else []
        weekly_average = len(week_data) / 7.0 if week_data else 0.0
        
        # Calculate streak
        streak = 0
        current_date = today
        
        while True:
            start_of_day = f"{current_date}T00:00:00"
            end_of_day = f"{current_date + timedelta(days=1)}T00:00:00"
            
            check_response = supabase.table("exercise_completions")\
                .select("id")\
                .filter("user_id", "eq", user_id)\
                .gte("completed_at", start_of_day)\
                .lt("completed_at", end_of_day)\
                .execute()
            
            if not check_response.data or len(check_response.data) == 0:
                break
            
            streak += 1
            current_date = current_date - timedelta(days=1)
        
        return {
            "completed_today": completed_today,
            "total_duration": total_duration,
            "weekly_average": round(weekly_average, 2),
            "streak": streak
        }
    except Exception as e:
        logger.error(f"Error fetching user stats: {str(e)}")
        # Return default stats on error
        return {
            "completed_today": 0,
            "total_duration": 0,
            "weekly_average": 0.0,
            "streak": 0
        }


@router.get("/trending")
async def get_trending(limit: int = Query(10)):
    """
    Get trending exercises based on completion count.
    Returns the most completed exercises in the last 7 days.
    """
    try:
        week_ago = (datetime.now() - timedelta(days=7)).isoformat()
        
        response = supabase.table("exercise_completions")\
            .select("exercise_id")\
            .gte("completed_at", week_ago)\
            .execute()
        
        if not response.data:
            # Return all exercises if no completions
            all_response = supabase.table("exercises")\
                .select("*")\
                .filter("is_active", "eq", True)\
                .limit(limit)\
                .execute()
            return all_response.data if all_response.data else []
        
        # Count occurrences
        count_map = {}
        for completion in response.data:
            ex_id = completion["exercise_id"]
            count_map[ex_id] = count_map.get(ex_id, 0) + 1
        
        # Get exercise details for top exercises
        trending_ids = sorted(count_map.items(), key=lambda x: x[1], reverse=True)[:limit]
        
        trending_exercises = []
        for ex_id, count in trending_ids:
            ex_response = supabase.table("exercises")\
                .select("*")\
                .eq("id", ex_id)\
                .execute()
            
            if ex_response.data:
                ex = ex_response.data[0]
                chat_flow = ex.get("chat_flow", [])
                if isinstance(chat_flow, str):
                    try:
                        chat_flow = json.loads(chat_flow)
                    except json.JSONDecodeError:
                        chat_flow = []
                
                trending_exercises.append({
                    "id": ex["id"],
                    "name": ex["exercise_name"],
                    "duration": ex["duration"],
                    "category": ex["category_name"],
                    "category_image_path": ex["category_image_path"],
                    "description": ex["exercise_description"],
                    "completions": count,
                    "chat_flow": chat_flow
                })
        
        return trending_exercises
    except Exception as e:
        logger.error(f"Error fetching trending exercises: {str(e)}")
        return []
