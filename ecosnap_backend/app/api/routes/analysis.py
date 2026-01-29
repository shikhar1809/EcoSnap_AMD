from fastapi import APIRouter, File, UploadFile, HTTPException, Form
from typing import List
from app.services.ai_service import AIService

router = APIRouter()

# from fastapi import Form

@router.post("/analyze/context")
async def analyze_context(
    files: List[UploadFile] = File(...),
    user_note: str = Form(None)
):
    """
    Step 1: Analyzes image to generate context-specific questions.
    """
    if not files: raise HTTPException(status_code=400, detail="No files")
    
    file = files[0]
    contents = await file.read()
    
    # Quick Object Detection
    detected_objects = AIService.detect_objects(contents)
    
    # Generate Questions
    result = AIService.generate_questions(contents, detected_objects, user_note)
    return result

@router.post("/analyze")
async def analyze_room(
    files: List[UploadFile] = File(...),
    user_responses: str = Form("{}") # JSON string of answers
):
    """
    Step 2: Full Analysis with User Answers.
    """
    if not files: raise HTTPException(status_code=400, detail="No files uploaded")

    file = files[0]
    contents = await file.read()
    
    import json
    try:
        responses_dict = json.loads(user_responses)
    except:
        responses_dict = {"budget": user_responses} # Fallback
    
    # 1. Detect Objects
    detected_objects = AIService.detect_objects(contents)
    
    # 2. Analyze with Gemini + User Context
    analysis_result = AIService.analyze_with_gemini(contents, detected_objects, responses_dict)
    
    # 3. Depth Map
    from app.services.depth_service import DepthService
    depth_map_base64 = DepthService.generate_depth_map(contents)

    response = {
        "room_id": file.filename,
        "message": "Analysis Complete",
        "detected_objects": detected_objects,
        "depth_map": depth_map_base64,
    }
    response.update(analysis_result)
    
    return response
