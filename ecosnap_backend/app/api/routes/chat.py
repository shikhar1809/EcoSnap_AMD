from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import google.generativeai as genai
from app.core.config import get_settings
import edge_tts
import asyncio
import base64
import tempfile
import os

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
    Returns text response AND base64 audio.
    """
    try:
        prompt = f"""
        You are "EcoSnap Advisor", a friendly Indian sustainability expert speaking to a user.
        User Context: {request.context}
        User Question: {request.message}
        
        Answer as if you are speaking. 
        - Keep it short (2-3 sentences max).
        - Use simple, direct language.
        - Focus on saving money (₹) and quick tips.
        - Do not use markdown lists or complex formatting.
        """
        
        # 1. Generate Text
        response = model.generate_content(prompt)
        text_response = response.text
        
        # 2. Generate Audio (Edge TTS)
        # Voice: en-IN-NeerjaNeural (Female, Indian Accent)
        communicate = edge_tts.Communicate(text_response, "en-IN-NeerjaNeural")
        
        with tempfile.NamedTemporaryFile(delete=False, suffix=".mp3") as fp:
            temp_filename = fp.name

        await communicate.save(temp_filename)

        with open(temp_filename, "rb") as fp:
            audio_bytes = fp.read()
            audio_base64 = base64.b64encode(audio_bytes).decode("utf-8")
        
        # Cleanup
        os.unlink(temp_filename)

        return {
            "response": text_response,
            "audio": audio_base64
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
