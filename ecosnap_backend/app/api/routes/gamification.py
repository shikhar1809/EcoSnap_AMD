from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from app.database import supabase
from datetime import datetime, timedelta

router = APIRouter()

class RewardRequest(BaseModel):
    user_id: str
    action: str # e.g., "scan_upload", "read_tip"
    carbon_kg: float = 0.0 # Optional carbon saved

POINTS_MAP = {
    "scan_upload": 50,
    "read_tip": 10,
    "share_app": 100
}

@router.post("/reward")
async def reward_user(request: RewardRequest):
    """
    Award points to a user for an action. Optionally track carbon saved.
    """
    points = POINTS_MAP.get(request.action, 0)
    if points == 0:
        return {"message": "No points for this action"}

    try:
        # Get current user data
        user_res = supabase.table("users").select("points, streak_days, last_active_date, carbon_saved").eq("id", request.user_id).execute()
        if not user_res.data:
            raise HTTPException(status_code=404, detail="User not found")
        
        user_data = user_res.data[0]
        current_points = user_data.get("points") or 0
        current_streak = user_data.get("streak_days") or 0
        current_carbon = user_data.get("carbon_saved") or 0.0
        last_active_str = user_data.get("last_active_date")
        
        # Calculate new values
        new_points = current_points + points
        new_carbon = current_carbon + request.carbon_kg
        
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
            "carbon_saved": new_carbon,
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
    Get current user's points, streak, carbon saved, and tier.
    """
    try:
        user_res = supabase.table("users").select("points, streak_days, carbon_saved, subscription_tier").eq("id", user_id).execute()
        if not user_res.data:
            return {"points": 0, "streak_days": 0, "carbon_saved": 0.0, "tier": "Green Starter"}
            
        return user_res.data[0]
    except Exception as e:
        print(f"Status Error: {e}")
        return {"points": 0, "streak_days": 0, "carbon_saved": 0.0, "tier": "Green Starter"}

# --- Marketplace Endpoints ---

@router.get("/marketplace")
async def get_marketplace_items():
    """
    List all available marketplace items.
    """
    try:
        # Select items where stock is -1 (infinite) or > 0
        response = supabase.table("marketplace").select("*").or_("stock.eq.-1,stock.gt.0").execute()
        return response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

class RedeemRequest(BaseModel):
    user_id: str
    item_id: str

@router.post("/redeem")
async def redeem_item(request: RedeemRequest):
    """
    Redeem an item using points.
    """
    try:
        # 1. Fetch Item Details
        item_res = supabase.table("marketplace").select("*").eq("id", request.item_id).execute()
        if not item_res.data:
            raise HTTPException(status_code=404, detail="Item not found")
        item = item_res.data[0]
        cost = item['cost_points']
        
        # 2. Fetch User Balance
        user_res = supabase.table("users").select("points").eq("id", request.user_id).execute()
        if not user_res.data:
            raise HTTPException(status_code=404, detail="User not found")
        current_points = user_res.data[0]['points']
        
        # 3. Check Balance
        if current_points < cost:
            raise HTTPException(status_code=400, detail=f"Insufficient points. Need {cost}, have {current_points}.")
            
        # 4. Deduct Points & Record Redemption
        # Ideally this should be a transaction/RPC, but doing sequential for MVP.
        
        # Deduct
        new_points = current_points - cost
        supabase.table("users").update({"points": new_points}).eq("id", request.user_id).execute()
        
        # Record
        supabase.table("redemptions").insert({
            "user_id": request.user_id,
            "item_id": request.item_id
        }).execute()
        
        # Reduce Stock if not -1
        if item['stock'] != -1:
            new_stock = max(0, item['stock'] - 1)
            supabase.table("marketplace").update({"stock": new_stock}).eq("id", request.item_id).execute()
            
        return {
            "message": f"Successfully redeemed: {item['name']}",
            "remaining_points": new_points
        }
        
    except HTTPException as he:
        raise he
    except Exception as e:
        print(f"Redemption Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))
