from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from app.database import supabase

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
        # Get current points
        user_res = supabase.table("users").select("points, co2_saved").eq("id", request.user_id).execute()
        if not user_res.data:
            raise HTTPException(status_code=404, detail="User not found")
            
        current_points = user_res.data[0].get("points") or 0
        new_points = current_points + points
        
        # Update points
        supabase.table("users").update({"points": new_points}).eq("id", request.user_id).execute()
        
        return {"message": "Points awarded", "points_added": points, "total_points": new_points}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/leaderboard")
async def get_leaderboard():
    """
    Get top 10 users by points.
    """
    try:
        response = supabase.table("users").select("name, points, city").order("points", desc=True).limit(10).execute()
        return response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
