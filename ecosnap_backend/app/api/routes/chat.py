from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import google.generativeai as genai
from app.core.config import get_settings

settings = get_settings()
genai.configure(api_key=settings.GEMINI_API_KEY)
model = genai.GenerativeModel('gemini-2.0-flash')

router = APIRouter()

class ChatRequest(BaseModel):
    user_id: str
    message: str
    context: str = "" # Optional context like "Looking at AC analysis"

@router.post("/ask")
async def ask_advisor(request: ChatRequest):
    """
    Ask the AI Sustainability Advisor a question.
    """
    try:
        prompt = f"""
        You are "EcoSnap Advisor", a friendly and knowledgeable Indian home sustainability expert.
        User Context: {request.context}
        User Question: {request.message}
        
        Provide a helpful, encouraging, and specific answer. 
        Focus on ROI (Return on Investment) and practical Indian context (electricity rates ~₹8/unit).
        Keep it concise (under 100 words).
        """
        
        response = model.generate_content(prompt)
        return {"response": response.text}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
