from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

from app.services.community_service import CommunityService, ActionType

router = APIRouter()

# ==================== MODELS ====================

class PostActionRequest(BaseModel):
    user_id: str
    user_name: str
    action: ActionType
    city: str

# ==================== ENHANCED COMMUNITY ENDPOINTS ====================

@router.get("/leaderboard")
async def get_leaderboard(city: Optional[str] = None, limit: int = 10):
    """
    Get community leaderboard
    Real-time rankings with points, tiers, and badges
    """
    leaderboard = CommunityService.get_leaderboard(city=city, limit=limit)
    
    return {
        "leaderboard": leaderboard,
        "total_users": len(leaderboard),
        "city": city or "All Cities",
        "last_updated": datetime.now().isoformat()
    }

@router.get("/feed")
async def get_live_feed(city: Optional[str] = None, limit: int = 20):
    """
    Get live community feed
    Real-time actions from users
    """
    feed = CommunityService.get_live_feed(city=city, limit=limit)
    
    return {
        "feed": feed,
        "total_actions": len(feed),
        "city": city or "All Cities",
        "last_updated": datetime.now().isoformat()
    }

@router.get("/insights/{city}")
async def get_neighborhood_insights(city: str):
    """
    Get neighborhood insights and social proof
    "41 homes in your area went solar"
    """
    insights = CommunityService.get_neighborhood_insights(city=city)
    
    return insights

@router.post("/post")
async def post_action(req: PostActionRequest):
    """
    Post a new action to the community feed
    Earn points and update leaderboard
    """
    result = CommunityService.post_action(
        user_id=req.user_id,
        user_name=req.user_name,
        action=req.action,
        city=req.city
    )
    
    return result

@router.get("/user/{user_id}")
async def get_user_stats(user_id: str):
    """Get user statistics and achievements"""
    stats = CommunityService.get_user_stats(user_id)
    return stats

@router.get("/challenges/{city}")
async def get_challenges(city: str):
    """Get active community challenges"""
    challenges = CommunityService.get_challenges(city)
    
    return {
        "challenges": challenges,
        "total": len(challenges),
        "city": city
    }

# ==================== LEGACY ENDPOINTS (Supabase Q&A) ====================

from app.database import supabase

class QuestionCreate(BaseModel):
    user_id: str
    user_name: str
    title: str
    content: str
    category: str = "General"
    city: Optional[str] = None

class AnswerCreate(BaseModel):
    user_id: str
    user_name: str
    question_id: str
    content: str

@router.post("/questions")
async def ask_question(q: QuestionCreate):
    try:
        data = q.dict()
        response = supabase.table("questions").insert(data).execute()
        if not response.data:
            raise HTTPException(status_code=500, detail="Failed to create question")
        return response.data[0]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/questions")
async def list_questions(category: Optional[str] = None, city: Optional[str] = None):
    try:
        query = supabase.table("questions").select("*").order("created_at", desc=True)
        if category:
            query = query.eq("category", category)
        if city:
            query = query.eq("city", city)
            
        response = query.execute()
        return response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/answers")
async def answer_question(a: AnswerCreate):
    try:
        data = a.dict()
        response = supabase.table("answers").insert(data).execute()
        
        # Increment answer count
        try:
            q_res = supabase.table("questions").select("answer_count").eq("id", a.question_id).execute()
            if q_res.data:
                current_count = q_res.data[0]['answer_count']
                supabase.table("questions").update({"answer_count": current_count + 1}).eq("id", a.question_id).execute()
        except:
            pass
            
        return response.data[0]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/questions/{question_id}/answers")
async def get_answers(question_id: str):
    try:
        response = supabase.table("answers").select("*").eq("question_id", question_id).order("created_at", desc=True).execute()
        return response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/vote")
async def vote(item_id: str, item_type: str = "question"):
    try:
        table = "questions" if item_type == "question" else "answers"
        
        res = supabase.table(table).select("upvotes").eq("id", item_id).execute()
        if not res.data:
            raise HTTPException(status_code=404, detail="Item not found")
            
        current_votes = res.data[0]['upvotes']
        new_votes = current_votes + 1
        
        update_res = supabase.table(table).update({"upvotes": new_votes}).eq("id", item_id).execute()
        return {"message": "Upvoted", "new_count": new_votes}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
