from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from app.database import supabase
from datetime import datetime, timedelta

router = APIRouter()

class RewardRequest(BaseModel):
    user_id: str
    action: str # e.g., "scan_upload", "read_tip"

POINTS_MAP = {
    "scan_upload": 50,
    "read_tip": 10,
    "share_app": 100
}

@router.post("/reward")
async def reward_user(request: RewardRequest):
    """
    Award points to a user for an action.
    """
    points = POINTS_MAP.get(request.action, 0)
    if points == 0:
        return {"message": "No points for this action"}

    try:
        # Get current user data
        user_res = supabase.table("users").select("points, streak_days, last_active_date").eq("id", request.user_id).execute()
        if not user_res.data:
            raise HTTPException(status_code=404, detail="User not found")
        
        user_data = user_res.data[0]
        current_points = user_data.get("points") or 0
        current_streak = user_data.get("streak_days") or 0
        last_active_str = user_data.get("last_active_date")
        
        # Calculate new points
        new_points = current_points + points
        
        # Streak Logic
        today = datetime.now().date()
        today_str = today.isoformat()
        new_streak = current_streak
        
        if last_active_str:
            last_active = datetime.fromisoformat(last_active_str).date()
            if last_active == today:
                pass # Already active today
            elif last_active == today - timedelta(days=1):
                new_streak += 1 # Consecutive day
            else:
                new_streak = 1 # Streak broken
        else:
            new_streak = 1 # First activity
            
        # Update user
        update_data = {
            "points": new_points,
            "streak_days": new_streak,
            "last_active_date": today_str
        }
        
        # Determine Tier
        # Tier 1: Green Starter (Default)
        # Tier 2: Circular Hero (> 500 points)
        # Tier 3: Planet Guardian (> 2000 points)
        
        tier = "Green Starter"
        if new_points >= 2000:
            tier = "Planet Guardian"
        elif new_points >= 500:
            tier = "Circular Hero"
            
        update_data["subscription_tier"] = tier # storage in db as subscription_tier for simplicity
        
        supabase.table("users").update(update_data).eq("id", request.user_id).execute()
        
        return {
            "message": "Points awarded", 
            "points_added": points, 
            "total_points": new_points,
            "streak_days": new_streak,
            "tier": tier
        }
    except Exception as e:
        print(f"Gamification Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/leaderboard")
async def get_leaderboard():
    """
    Get top 10 users by points.
    """
    try:
        response = supabase.table("users").select("name, points, city, streak_days").order("points", desc=True).limit(10).execute()
        return response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/status/{user_id}")
async def get_user_status(user_id: str):
    """
    Get current user's points, streak, and tier.
    """
    try:
        user_res = supabase.table("users").select("points, streak_days, subscription_tier").eq("id", user_id).execute()
        if not user_res.data:
            return {"points": 0, "streak_days": 0, "tier": "Green Starter"}
            
        return user_res.data[0]
    except Exception as e:
        print(f"Status Error: {e}")
        return {"points": 0, "streak_days": 0, "tier": "Green Starter"}
