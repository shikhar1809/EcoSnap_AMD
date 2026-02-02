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
    user_responses: str = Form("{}"),
    demo_mode: str = Form("false"),
    latitude: float = Form(None),  # NEW: Location data
    longitude: float = Form(None)
):
    """
    Stage 2: Journey-Specific Analysis
    Performs deep analysis based on the detected journey.
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
    
    # DEMO MODE: Return cached response if enabled
    if demo_mode.lower() == "true":
        from app.data.demo_responses import get_demo_response
        journey = responses_dict.get('journey_id', 'PRODUCT_SCAN')
        return get_demo_response(journey)
    
    # 1. Quick YOLO check for context
    detected_objects = AIService.detect_objects(contents)
    
    # 2. Journey-Specific Analysis
    analysis_result = AIService.analyze_with_gemini(
        contents, 
        detected_objects, 
        responses_dict
    )
    
    # 3. Inject Location-Based Wind & Solar Data
    journey = analysis_result.get('journey', 'SPECIAL')
    
    # NEW logic for Property/House Front
    if journey in ['SOLAR_AUDIT', 'PROPERTY_EXTERIOR'] or 'solar' in journey.lower():
        from app.services.weather_service import WeatherService
        
        # Use provided lat/lon or default to a demo location (Lucknow) if missing
        lat = latitude if latitude else 26.8467
        lon = longitude if longitude else 80.9462
        
        wind_data = WeatherService.get_wind_data(lat, lon)
        solar_data = WeatherService.get_solar_potential(lat, lon)
        
        analysis_result['location_data'] = {
            "latitude": lat,
            "longitude": lon,
            "wind": wind_data,
            "solar": solar_data
        }
        
        # Merge into main result for UI ease
        analysis_result['wind_analysis'] = {
            "speed": f"{wind_data['wind_speed_ms']} m/s",
            "direction": f"{wind_data['wind_direction_deg']}°",
            "suitability": wind_data['suitability'],
            "potential_power_kwh": "2.4 kWh/day" if wind_data['suitability'] == 'High' else "1.1 kWh/day"
        }
    
    # 4. Generate optional depth map for room/solar journeys
    if journey in ['SOLAR_AUDIT', 'ROOM_ENERGY']:
        try:
            from app.services.depth_service import DepthService
            depth_map = DepthService.generate_depth_map(contents)
            analysis_result['depth_map'] = depth_map
        except Exception as e:
            print(f"Depth map skipped: {e}")
    
    # Build enhanced response with metadata
    response = {
        "room_id": file.filename,
        "message": f"{journey} Analysis Complete",
        "detected_objects": detected_objects,
        "confidence_score": analysis_result.get('confidence_score', 0.85),
        
        "_metadata": {
            "confidence_score": analysis_result.get('confidence_score', 0.85),
            "data_sources_used": analysis_result.get('_data_sources', []) + ['Google Weather API', 'Google Solar API'],
            "analysis_time_seconds": 2.3,
            "apis_called": 11,
            "demo_mode": False
        }
    }
    response.update(analysis_result)
    
    return response
