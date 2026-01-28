from fastapi import APIRouter, File, UploadFile, HTTPException
from typing import List
from app.services.ai_service import AIService

router = APIRouter()

@router.post("/analyze")
async def analyze_room(files: List[UploadFile] = File(...)):
    """
    Analyzes uploaded room images using YOLOv8 (local) and Gemini Vision (Cloud).
    """
    if not files:
        raise HTTPException(status_code=400, detail="No files uploaded")

    # Process first image for MVP
    file = files[0]
    contents = await file.read()
    
    # 1. Detect Objects (YOLO)
    detected_objects = AIService.detect_objects(contents)
    
    # 2. Analyze with Gemini
    analysis_result = AIService.analyze_with_gemini(contents, detected_objects)
    
    return {
        "room_id": file.filename,
        "message": "Analysis Complete",
        "detected_objects": detected_objects,
        "appliances": analysis_result.get("appliances", []),
        "efficiency_score": analysis_result.get("efficiency_score", 0),
        "recommendation": analysis_result.get("recommendation", "No recommendation available."),
        "green_architecture": analysis_result.get("green_architecture", {})
    }
