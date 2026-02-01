from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
import uuid

router = APIRouter()

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

# Supabase handles ID and CreatedAt automatically via defaults, 
# but models can still reflect them for response validation if needed.

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
        # Check if question exists first? Not strictly necessary with FK constraints, 
        # but good for error messaging. Supabase will throw error if FK fails.
        
        data = a.dict()
        response = supabase.table("answers").insert(data).execute()
        
        # Increment answer count on question (Manual denormalization update)
        # Ideally this is a trigger or RPC, but we do it client-side for MVP
        try:
            # Get current count
            q_res = supabase.table("questions").select("answer_count").eq("id", a.question_id).execute()
            if q_res.data:
                current_count = q_res.data[0]['answer_count']
                supabase.table("questions").update({"answer_count": current_count + 1}).eq("id", a.question_id).execute()
        except:
            pass # Non-critical
            
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
async def vote(item_id: str, item_type: str = "question"): # item_type: question or answer
    try:
        table = "questions" if item_type == "question" else "answers"
        
        # Simple increment via read-modify-write (Not atomic, but fine for MVP)
        # Better: Use a Postgres Function (RPC) 'increment_vote'
        
        res = supabase.table(table).select("upvotes").eq("id", item_id).execute()
        if not res.data:
            raise HTTPException(status_code=404, detail="Item not found")
            
        current_votes = res.data[0]['upvotes']
        new_votes = current_votes + 1
        
        update_res = supabase.table(table).update({"upvotes": new_votes}).eq("id", item_id).execute()
        return {"message": "Upvoted", "new_count": new_votes}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
