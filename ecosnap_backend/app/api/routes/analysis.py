from fastapi import APIRouter, File, UploadFile, HTTPException, Form
from typing import List
from app.services.ai_service import AIService

router = APIRouter()

@router.post("/analyze/context")
async def analyze_context(
    files: List[UploadFile] = File(...),
    user_note: str = Form(None),
    scan_mode: str = Form("quick")  # NEW: quick or deep
):
    """
    Stage 1: Smart Triage
    Classifies the image and generates context-specific questions.
    
    - Quick mode: Fewer questions, auto-proceed if high confidence
    - Deep mode: Detailed questions, always shows triage dialog
    """
    if not files: 
        raise HTTPException(status_code=400, detail="No files uploaded")
    
    file = files[0]
    contents = await file.read()
    
    # 1. Quick Object Detection with YOLO
    detected_objects = AIService.detect_objects(contents)
    
    # 2. Smart Triage with Gemini
    result = AIService.generate_questions(
        contents, 
        detected_objects, 
        user_note,
        scan_mode=scan_mode  # Pass scan mode
    )
    
    # Add detected objects to response
    result['detected_objects'] = detected_objects
    
    return result

@router.post("/analyze")
async def analyze_image(
    files: List[UploadFile] = File(...),
    user_responses: str = Form("{}")
):
    """
    Stage 2: Journey-Specific Analysis
    Performs deep analysis based on the detected journey.
    
    Each journey returns ONLY its relevant data:
    - SOLAR_AUDIT: Solar potential, subsidies, ROI
    - ROOM_ENERGY: Appliances, efficiency, vampire power
    - PRODUCT_SCAN: Carbon footprint, alternatives, materials
    - BILL_OCR: Tariff breakdown, reduction strategies
    - FOOD_AUDIT: Food carbon, swaps, food miles
    - VEHICLE_CHECK: Emissions, EV comparison
    """
    if not files: 
        raise HTTPException(status_code=400, detail="No files uploaded")

    file = files[0]
    contents = await file.read()
    
    # Parse user responses
    import json
    try:
        responses_dict = json.loads(user_responses)
    except:
        responses_dict = {"journey_id": "SPECIAL"}
    
    # 1. Quick YOLO check for context
    detected_objects = AIService.detect_objects(contents)
    
    # 2. Journey-Specific Analysis
    analysis_result = AIService.analyze_with_gemini(
        contents, 
        detected_objects, 
        responses_dict
    )
    
    # 3. Generate optional depth map for room/solar journeys
    journey = analysis_result.get('journey', 'SPECIAL')
    if journey in ['SOLAR_AUDIT', 'ROOM_ENERGY']:
        try:
            from app.services.depth_service import DepthService
            depth_map = DepthService.generate_depth_map(contents)
            analysis_result['depth_map'] = depth_map
        except Exception as e:
            print(f"Depth map skipped: {e}")
    
    # Build response
    response = {
        "room_id": file.filename,
        "message": f"{journey} Analysis Complete",
        "detected_objects": detected_objects,
    }
    response.update(analysis_result)
    
    return response
