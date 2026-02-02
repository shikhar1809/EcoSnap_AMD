"""
EcoSnap AI Service v2.0 - Precision Analysis Engine
Each journey has a DEDICATED prompt that returns ONLY relevant data.
"""
import google.generativeai as genai
from ultralytics import YOLO
from PIL import Image
import io
import json
import os
from app.core.config import get_settings

settings = get_settings()

# Initialize Gemini Models
genai.configure(api_key=settings.GEMINI_API_KEY)

# Quick Scan: Fast triage with Gemini 2.0 Flash
model_triage = genai.GenerativeModel(
    'gemini-2.0-flash',
    generation_config={'temperature': 0.3}
)

# Deep Analysis: Comprehensive with Gemini 2.0 Flash
model_analysis = genai.GenerativeModel(
    'gemini-2.0-flash',
    generation_config={'temperature': 0.4}
)

# Initialize YOLO for object detection
model_yolo = YOLO("yolov8n.pt")

# ============================================================
# JOURNEY-SPECIFIC PROMPT TEMPLATES
# Each journey returns ONLY its relevant fields
# ============================================================

JOURNEY_PROMPTS = {
    "SOLAR_AUDIT": """
You are EcoSnap's Advanced Solar Intelligence System. Analyze this property exterior image with EXTREME PRECISION.

CRITICAL ANALYSIS REQUIREMENTS:
1. **3D Spatial Analysis**: Estimate roof dimensions, tilt angle, orientation (compass direction)
2. **Material Detection**: Identify roof material (RCC/Tile/Metal/Asbestos) - affects load capacity
3. **Shading Analysis**: Detect trees, buildings, chimneys causing shadows - be SPECIFIC about locations
4. **Structural Assessment**: Roof condition, waterproofing needs, access difficulty
5. **Environmental Context**: Visible weather patterns, pollution levels, nearby obstructions

ADVANCED CALCULATIONS:
- Use visible architectural cues to estimate actual dimensions
- Calculate optimal panel tilt based on visible roof angle
- Identify best placement zones (mark as Zone A, B, C with panel counts)
- Estimate sun exposure hours based on visible shading and orientation

OUTPUT JSON:
{{
    "journey": "SOLAR_AUDIT",
    "type": "property_exterior",
    "product_name": "Advanced Solar Potential Analysis",
    
    "roof_3d_analysis": {{
        "estimated_area_sqm": number,
        "usable_area_sqm": number,
        "tilt_angle_degrees": number,
        "orientation": "North/South/East/West/SE/SW/NE/NW",
        "roof_material": "RCC/Tile/Metal/Asbestos/Unknown",
        "structural_integrity": "Excellent/Good/Fair/Poor",
        "load_capacity_assessment": "Can support Xkw system"
    }},
    
    "shading_analysis": {{
        "shading_score": 0-100,
        "obstacles": [
            {{"type": "Tree/Building/Chimney", "location": "North-East corner", "impact": "15% loss in morning"}}
        ],
        "optimal_sun_hours_daily": number,
        "seasonal_variation": "Summer: Xh, Winter: Yh"
    }},
    
    "panel_placement_zones": [
        {{
            "zone_id": "A",
            "area_sqm": number,
            "panel_count": number,
            "orientation": "South",
            "tilt": number,
            "annual_generation_kwh": number,
            "priority": "High/Medium/Low"
        }}
    ],
    
    "solar_potential": {{
        "viability_score": 0-100,
        "recommended_capacity_kw": number,
        "estimated_annual_generation_kwh": number,
        "capacity_factor": 0.15-0.20,
        "degradation_rate_annual": 0.5
    }},
    
    "financial_analysis": {{
        "system_cost_per_kw": 70000,
        "total_system_cost": number,
        "pm_surya_ghar_subsidy": number,
        "state_subsidy_estimate": number,
        "net_investment": number,
        "monthly_generation_kwh": number,
        "monthly_savings_inr": number,
        "payback_years": number,
        "25_year_savings": number,
        "irr_percent": number
    }},
    
    "installation_considerations": {{
        "roof_access": "Easy/Moderate/Difficult",
        "waterproofing_needed": true/false,
        "structural_reinforcement": "None/Minor/Major",
        "grid_connection_distance_m": number,
        "installation_complexity": "Low/Medium/High"
    }},
    
    "recommendation": "Detailed recommendation with specific next steps",
    "confidence_score": 0.0-1.0
}}

BE EXTREMELY DETAILED. Use visible cues to make accurate estimates. This is production-grade analysis.
""",


    "ROOM_ENERGY": """
You are EcoSnap's Advanced Room Energy Intelligence System. Analyze this room with 3D SPATIAL AWARENESS.

CRITICAL ANALYSIS REQUIREMENTS:
1. **3D Room Estimation**: Estimate room dimensions (length x width x height in meters) from visible cues
2. **Thermal Analysis**: Window placement, sunlight exposure, insulation quality from visible materials
3. **Appliance Detection**: Identify ALL appliances with precise specifications
4. **Spatial Relationships**: Note appliance placement relative to windows, walls, heat sources
5. **Material Analysis**: Wall material, window type (single/double pane), ceiling material

ADVANCED CALCULATIONS:
- Calculate room volume for AC sizing accuracy
- Estimate heat gain from windows based on size and orientation
- Detect inefficient appliance placement (e.g., AC near window)
- Calculate vampire power from standby devices
- Estimate thermal load and cooling requirements

OUTPUT JSON:
{{
    "journey": "ROOM_ENERGY",
    "type": "room_interior",
    "product_name": "Advanced 3D Room Energy Audit",
    
    "room_3d_analysis": {{
        "estimated_length_m": number,
        "estimated_width_m": number,
        "estimated_height_m": number,
        "volume_m3": number,
        "room_type": "Living/Bedroom/Kitchen/Office",
        "window_count": number,
        "window_area_sqm": number,
        "window_orientation": "North/South/East/West",
        "natural_ventilation_score": 0-100
    }},
    
    "thermal_analysis": {{
        "wall_material": "Concrete/Brick/Wood/Unknown",
        "window_type": "Single-pane/Double-pane/Unknown",
        "insulation_quality": "Excellent/Good/Poor",
        "heat_sources": ["South window", "AC unit", "Electronics"],
        "estimated_heat_gain_watts": number,
        "thermal_comfort_score": 0-100
    }},
    
    "detected_appliances": [
        {{
            "name": "Air Conditioner",
            "type": "AC",
            "capacity_ton": number,
            "placement": "Near south window",
            "placement_efficiency": "Optimal/Suboptimal/Poor",
            "estimated_power_watts": number,
            "estimated_star_rating": "1-5 or Unknown",
            "usage_hours_daily": number,
            "monthly_cost_inr": number,
            "efficiency_issues": ["Direct sunlight increases load"],
            "upgrade_suggestion": "Move to north wall or add curtains",
            "potential_savings_inr": number
        }}
    ],
    
    "ac_sizing_analysis": {{
        "room_volume_m3": number,
        "required_capacity_ton": number,
        "current_capacity_ton": number,
        "sizing_status": "Undersized/Optimal/Oversized",
        "oversizing_percent": number,
        "annual_waste_inr": number,
        "recommendation": "Specific AC sizing advice"
    }},
    
    "vampire_power_analysis": {{
        "total_standby_watts": number,
        "annual_cost_inr": number,
        "devices": [
            {{"device": "TV + Set-top box", "watts": 18, "annual_cost": 630}}
        ],
        "smart_plug_recommendation": true/false,
        "smart_plug_roi_months": number
    }},
    
    "lighting_analysis": {{
        "bulb_count": number,
        "bulb_types": {{"LED": X, "CFL": Y, "Incandescent": Z}},
        "led_conversion_savings": number,
        "natural_light_score": 0-100,
        "smart_lighting_potential": "Motion sensors = ₹X/year"
    }},
    
    "spatial_optimization": [
        {{
            "appliance": "AC",
            "current_location": "Near window",
            "issue": "Direct sunlight increases cooling load by 30%",
            "recommendation": "Add blackout curtains or relocate",
            "savings_potential": 4800
        }}
    ],
    
    "appliances": [
        {{
            "type": "Same as name above",
            "efficiency_rating": "X-star",
            "current_power_consumption": "X Watts",
            "recommended_replacement": "Efficient Alternative",
            "financial_savings_year": "₹X"
        }}
    ],
    
    "green_architecture": {{
        "layout_advice": "Summary of spatial optimization advice",
        "sustainable_additions": "Summary of quick wins and additions"
    }},
    
    "quick_wins": [
        {{"action": "LED bulb replacement", "cost": 500, "annual_savings": 2400, "payback_months": 3}}
    ],
    
    "efficiency_score": 0-100,
    "total_potential_savings_annual": number,
    "recommendation": "Detailed room-specific recommendations with priorities",
    "confidence_score": 0.0-1.0
}}

BE EXTREMELY DETAILED. Estimate dimensions from furniture scale. Note all spatial relationships. This is production-grade analysis.
""",


    "PRODUCT_SCAN": """
You are EcoSnap's Product Lifecycle Intelligence System. Analyze this consumer product with EXTREME DETAIL.

CRITICAL ANALYSIS REQUIREMENTS:
1. **Product Identification**: Brand, model, size, material composition
2. **Full Lifecycle CO₂**: Manufacturing, transport, use phase, end-of-life
3. **Material Intelligence**: Recyclability, biodegradability, microplastic risk
4. **Circular Economy**: Trade-in value, repair options, upcycling potential
5. **Behavioral Economics**: Comparison to alternatives, social proof, nudges

ADVANCED CALCULATIONS:
- Estimate product lifespan and total lifecycle impact
- Calculate break-even point for sustainable alternatives
- Identify local recycling/disposal options
- Provide specific brand alternatives available in India

OUTPUT JSON:
{{
    "journey": "PRODUCT_SCAN",
    "type": "product",
    "product_name": "Detailed product description",
    "brand": "Brand name",
    "category": "Bottle/Watch/Electronics/Clothing/etc",
    
    "sustainability_grade": "A/B/C/D/F",
    
    "carbon_lifecycle": {{
        "total_grams_co2": number,
        "breakdown": {{
            "raw_material_extraction": number,
            "manufacturing": number,
            "transportation": number,
            "packaging": number,
            "use_phase": number,
            "end_of_life": number
        }},
        "comparison": "= Xkm car drive / Y trees needed to offset",
        "if_recycled_co2_saved": number,
        "if_landfilled_impact": "Takes X years to decompose"
    }},
    
    "material_intelligence": {{
        "primary_material": "PET Plastic/Glass/Aluminum/etc",
        "material_code": "#1 PET / #2 HDPE / etc",
        "recyclability_score": 0-100,
        "current_recycling_rate_india": "X%",
        "biodegradable": true/false,
        "decomposition_time_years": number,
        "microplastic_risk": "High/Medium/Low",
        "toxicity_level": "Safe/Moderate/Harmful"
    }},
    
    "green_alternatives": [
        {{
            "product": "Reusable steel bottle",
            "brand": "Milton/Cello",
            "upfront_cost_inr": number,
            "co2_per_use_grams": number,
            "break_even_uses": number,
            "annual_savings_co2_kg": number,
            "annual_savings_money_inr": number,
            "availability": "Amazon/Local stores",
            "rating": 4.5
        }}
    ],
    
    "circular_economy": {{
        "repairable": true/false,
        "trade_in_value_inr": number,
        "refurbishment_options": ["Brand take-back program"],
        "upcycling_ideas": ["Use as planter"],
        "proper_disposal": "Drop at X recycling center"
    }},
    
    "behavioral_nudge": {{
        "message": "Switching to reusable saves ₹X/year and Ykg CO₂",
        "social_proof": "Z EcoSnap users made this switch",
        "gamification": "Unlock 'Plastic Warrior' badge after 30 days",
        "urgency": "This product will take X years to decompose"
    }},
    
    "recommendation": "Detailed actionable recommendation with specific next steps",
    "confidence_score": 0.0-1.0
}}

BE SPECIFIC. Provide real brand names, actual prices, and concrete comparisons. This is production-grade analysis.
""",


    "BILL_OCR": """
You are EcoSnap's Bill Analyzer. Extract and analyze this utility bill.

FOCUS ONLY ON:
1. OCR the bill - extract units, amount, tariff
2. Compare to typical usage
3. Identify tariff slab position
4. Suggest reduction strategies

OUTPUT JSON:
{{
    "journey": "BILL_OCR",
    "type": "document",
    "product_name": "Utility Bill Analysis",
    
    "extracted_data": {{
        "bill_type": "electricity/water/gas",
        "provider": "Company name",
        "billing_period": "Month Year",
        "units_consumed": number,
        "total_amount_inr": number,
        "rate_per_unit": number
    }},
    
    "analysis": {{
        "vs_average": "X% above/below area average",
        "slab_position": "Which tariff slab",
        "high_usage_flag": true/false
    }},
    
    "tariff_breakdown": [
        {{"slab": "0-100 units", "units": 100, "cost": 450}},
        {{"slab": "101-200 units", "units": 100, "cost": 650}}
    ],
    
    "reduction_strategies": [
        {{
            "strategy": "Description",
            "units_saved": number,
            "monthly_savings_inr": number,
            "implementation_cost": number
        }}
    ],
    
    "recommendation": "Main advice to reduce this bill",
    "confidence_score": 0.0-1.0
}}
""",

    "FOOD_AUDIT": """
You are EcoSnap's Food Carbon Analyzer. Analyze this food/meal image.

FOCUS ONLY ON:
1. Identify the food items
2. Estimate carbon footprint per ingredient
3. Suggest lower-carbon alternatives
4. Estimate food miles if identifiable

OUTPUT JSON:
{{
    "journey": "FOOD_AUDIT",
    "type": "food",
    "product_name": "Food item name",
    
    "carbon_footprint": {{
        "total_kg_co2": number,
        "breakdown": [
            {{"ingredient": "Meat", "kg_co2": 2.1, "percentage": 66}}
        ],
        "comparison_text": "Equivalent to X km drive"
    }},
    
    "greener_swaps": [
        {{
            "swap_from": "Chicken",
            "swap_to": "Paneer/Tofu",
            "carbon_reduction_percent": 70
        }}
    ],
    
    "food_miles": {{
        "estimated_km": number,
        "local_percentage": 50,
        "imported_items": ["Saffron", "Olive oil"]
    }},
    
    "recommendation": "Main advice for greener eating",
    "confidence_score": 0.0-1.0
}}
""",

    "VEHICLE_CHECK": """
You are EcoSnap's Vehicle Sustainability Analyzer. Analyze this vehicle.

FOCUS ONLY ON:
1. Identify vehicle type and estimated model
2. Estimate annual emissions
3. Compare to EV alternative
4. Calculate EV switch savings with subsidies

OUTPUT JSON:
{{
    "journey": "VEHICLE_CHECK",
    "type": "vehicle",
    "product_name": "Vehicle description",
    
    "vehicle_analysis": {{
        "type": "car/bike/scooter",
        "fuel_type": "petrol/diesel/cng/electric",
        "estimated_model": "Make Model Year",
        "estimated_mileage_kmpl": number
    }},
    
    "emissions": {{
        "annual_kg_co2": number,
        "based_on_km_year": 15000,
        "comparison_text": "X trees needed to offset"
    }},
    
    "ev_comparison": {{
        "recommended_ev": "EV Model Name",
        "ev_price_inr": number,
        "annual_fuel_savings": number,
        "annual_co2_reduction_percent": number,
        "fame_subsidy": number,
        "state_subsidy": number,
        "breakeven_years": number
    }},
    
    "recommendation": "Main advice about this vehicle",
    "confidence_score": 0.0-1.0
}}
""",


    "WIND_ANALYSIS": """
You are EcoSnap's Advanced Wind Energy Assessor. Analyze this location for micro-wind turbine potential.

CRITICAL ANALYSIS REQUIREMENTS:
1. **Obstruction Analysis**: Identify tall buildings, trees, or walls that block wind flow.
2. **Height Assessment**: Estimate height of mounting point (roof/pole) relative to surroundings.
3. **Terrain Context**: Open field, urban canyon, coastal, or hilltop features.
4. **Turbine Viability**: Can a vertical axis (VAWT) or horizontal axis (HAWT) turbine fit?

ADVANCED CALCULATIONS:
- Estimate turbulence intensity based on surface roughness (trees/buildings).
- Calculate potential swept area for a small turbine (e.g., 1-2m diameter).
- Assess structural suitability of roof/ground for mounting.

OUTPUT JSON:
{{
    "journey": "WIND_ANALYSIS",
    "type": "property_exterior",
    "product_name": "Micro-Wind Potential Assessment",
    
    "site_analysis": {{
        "roughness_class": "0 (Water) to 4 (Urban)",
        "estimated_hub_height_m": number,
        "obstacle_interference": "Low/Medium/High",
        "flow_quality": "Laminar/Turbulent"
    }},
    
    "wind_potential": {{
        "viability_score": 0-100,
        "recommended_turbine_type": "VAWT (Vertical)/HAWT (Horizontal)/None",
        "estimated_capacity_kw": number,
        "estimated_annual_generation_kwh": number
    }},
    
    "financial_analysis": {{
        "system_cost_estimate_inr": number,
        "payback_period_years": number,
        "roi_percent": number
    }},
    
    "installation_feasibility": {{
        "structural_integrity": "Suitable/Needs Reinforcement",
        "noise_impact_risk": "Low/High",
        "safety_zone_radius_m": number
    }},
    
    "recommendation": "Specific advice on turbine choice and placement",
    "confidence_score": 0.0-1.0
}}
""",

    "SPECIAL": """
You are EcoSnap's General Sustainability Advisor. Analyze this image for any eco-related insights.

Provide a helpful sustainability analysis based on what you see.

OUTPUT JSON:
{{
    "journey": "SPECIAL",
    "type": "general",
    "product_name": "Item/Scene description",
    
    "analysis": {{
        "what_i_see": "Description of the image",
        "sustainability_angle": "How this relates to sustainability",
        "impact_assessment": "Environmental impact if applicable"
    }},
    
    "suggestions": [
        "Suggestion 1",
        "Suggestion 2"
    ],
    
    "recommendation": "Main advice",
    "confidence_score": 0.0-1.0
}}
"""
}

# ============================================================
# TRIAGE PROMPT - Classifies image into the right journey
# ============================================================

TRIAGE_PROMPT = """
You are EcoSnap's Smart Triage System. Classify this image into exactly ONE journey.

YOLO detected: {yolo_objects}
User note: {user_note}
Scan mode: {scan_mode}

THE 7 JOURNEYS (choose ONE):
1. SOLAR_AUDIT → House exterior, rooftop, building facade, terrace (Primary for Buildings)
2. WIND_ANALYSIS → Open rooftop, farmland, windy terrain, high-rise balcony
3. ROOM_ENERGY → Furnished room with appliances (living room, office, bedroom)
4. PRODUCT_SCAN → Consumer product, bottle, gadget, clothing, packaging
5. BILL_OCR → Utility bill, electricity bill, receipt, document
6. FOOD_AUDIT → Food, meal, groceries, restaurant dish
7. VEHICLE_CHECK → Car, motorcycle, scooter, any vehicle

CRITICAL RULES FOR "HOUSE/BUILDING" IMAGES:
- If image shows a HOUSE/ROOF/BUILDING:
  - Default to "SOLAR_AUDIT".
  - If user explicitly mentions "wind" or "turbine", OR if context implies high altitude/open space, choose "WIND_ANALYSIS".
  - DO NOT choose "PRODUCT_SCAN" or "BILL_OCR" for a house.

RULES:
- If you see a BUILDING EXTERIOR → SOLAR_AUDIT (or WIND_ANALYSIS if appropriate)
- If you see a ROOM INTERIOR with furniture/appliances → ROOM_ENERGY
- If you see a SINGLE PRODUCT → PRODUCT_SCAN
- If you see TEXT/NUMBERS like a bill → BILL_OCR
- If you see FOOD → FOOD_AUDIT
- If you see a VEHICLE → VEHICLE_CHECK
- If unsure → SPECIAL

OUTPUT JSON:
{{
    "journey_id": "SOLAR_AUDIT|WIND_ANALYSIS|ROOM_ENERGY|PRODUCT_SCAN|BILL_OCR|FOOD_AUDIT|VEHICLE_CHECK|SPECIAL",
    "confidence": 0.0-1.0,
    "detected_category": "Short description (e.g., 'House with terrace', 'Water bottle')",
    "reasoning": "Why you chose this journey",
    
    "verification": {{
        "detected_category": "Short name",
        "question": "I see [X]. Do you want me to analyze [Y]?"
    }},
    
    "questions": {questions_spec}
}}
"""

QUESTIONS_QUICK = """[
    {"id": "confirm", "text": "Is this what you want to analyze?", "type": "select", "options": ["Yes", "No, something else"]}
]"""

QUESTIONS_DEEP = """[
    {"id": "q1", "text": "First detailed question based on the journey", "type": "text"},
    {"id": "q2", "text": "Second detailed question", "type": "text"},
    {"id": "q3", "text": "Third question if needed", "type": "select", "options": ["Option A", "Option B"]}
]"""


class AIService:
    @staticmethod
    def detect_objects(image_bytes: bytes) -> list:
        """Run YOLOv8 for fast object detection."""
        try:
            image = Image.open(io.BytesIO(image_bytes))
            results = model_yolo(image)
            
            detected = []
            for result in results:
                for box in result.boxes:
                    class_id = int(box.cls[0])
                    class_name = model_yolo.names[class_id]
                    conf = float(box.conf[0])
                    if conf > 0.3:  # Filter low confidence
                        detected.append({"name": class_name, "confidence": round(conf, 2)})
            
            return detected
        except Exception as e:
            print(f"YOLO Error: {e}")
            return []

    @staticmethod
    def generate_questions(image_bytes: bytes, detected_objects: list, user_note: str = None, scan_mode: str = "quick"):
        """
        Smart Triage System v2.0
        - Quick mode: 1-2 questions, auto-proceed if confidence > 0.85
        - Deep mode: 3-5 detailed questions
        """
        import asyncio
        import concurrent.futures
        
        try:
            image = Image.open(io.BytesIO(image_bytes))
            
            # Build context
            yolo_str = ", ".join([d['name'] for d in detected_objects]) if detected_objects else "None detected"
            questions_spec = QUESTIONS_QUICK if scan_mode == "quick" else QUESTIONS_DEEP
            
            prompt = TRIAGE_PROMPT.format(
                yolo_objects=yolo_str,
                user_note=user_note or "None",
                scan_mode=scan_mode,
                questions_spec=questions_spec
            )
            
            # Run Gemini call with timeout
            def _call_gemini():
                return model_triage.generate_content([prompt, image])
            
            with concurrent.futures.ThreadPoolExecutor() as executor:
                future = executor.submit(_call_gemini)
                try:
                    response = future.result(timeout=60)  # 60 second timeout
                except concurrent.futures.TimeoutError:
                    print(f"ERROR: Gemini triage timed out after 60s")
                    raise Exception("Gemini API timeout")
            
            text = AIService._clean_json_text(response.text)
            result = json.loads(text)
            
            # Add scan mode to result
            result['scan_mode'] = scan_mode
            
            # Auto-proceed logic for quick mode
            if scan_mode == "quick" and result.get('confidence', 0) > 0.85:
                result['auto_proceed'] = True
            else:
                result['auto_proceed'] = False
            
            print(f"DEBUG Triage: {result.get('journey_id')} (conf: {result.get('confidence')})")
            return result

        except Exception as e:
            print(f"Triage Error: {e}")
            return {
                "journey_id": "SPECIAL",
                "confidence": 0.3,
                "auto_proceed": False,
                "verification": {"detected_category": "Unknown", "question": "What would you like to analyze?"},
                "questions": []
            }

    @staticmethod
    def analyze_with_gemini(image_bytes: bytes, detected_objects: list, user_answers: dict):
        """
        Journey-Specific Analysis v2.0
        Each journey uses its own focused prompt.
        """
        import concurrent.futures
        
        journey_id = user_answers.get('journey_id', 'SPECIAL')
        print(f"DEBUG: Running {journey_id} analysis")
        
        try:
            image = Image.open(io.BytesIO(image_bytes))
            
            # Get journey-specific prompt
            prompt_template = JOURNEY_PROMPTS.get(journey_id, JOURNEY_PROMPTS['SPECIAL'])
            
            # Add user context if available
            context = f"\nUser provided context: {json.dumps(user_answers)}" if user_answers else ""
            
            # ENHANCED: Fetch geospatial context for location-aware analysis
            geospatial_context = ""
            location = user_answers.get('location', {})
            if location and location.get('latitude') and location.get('longitude'):
                try:
                    from app.services.google_api_service import GoogleAPIService
                    from app.services.geospatial_service import GeospatialService
                    
                    lat = location['latitude']
                    lon = location['longitude']
                    
                    print(f"DEBUG: Fetching geospatial data for {lat}, {lon}")
                    
                    # Fetch all geospatial data
                    geo_data = {}
                    
                    # Google APIs
                    weather = GoogleAPIService.get_weather_data(lat, lon)
                    if weather:
                        geo_data['weather'] = weather
                    
                    location_info = GoogleAPIService.get_location_context(lat, lon)
                    if location_info:
                        geo_data['location'] = location_info
                    
                    # Only fetch solar data for SOLAR_AUDIT journey
                    if journey_id == 'SOLAR_AUDIT':
                        solar = GoogleAPIService.get_solar_potential(lat, lon)
                        if solar:
                            geo_data['google_solar'] = solar
                    
                    # Open-source geospatial data
                    elevation = GeospatialService.get_elevation(lat, lon)
                    if elevation:
                        geo_data['elevation_m'] = elevation
                    
                    nasa_solar = GeospatialService.get_nasa_solar_data(lat, lon)
                    if nasa_solar:
                        geo_data['nasa_solar'] = nasa_solar
                    
                    osm_buildings = GeospatialService.get_osm_building_data(lat, lon)
                    if osm_buildings:
                        geo_data['osm_buildings'] = osm_buildings
                    
                    sun_position = GeospatialService.calculate_sun_position(lat, lon)
                    geo_data['sun_position'] = sun_position
                    
                    climate_zone = GeospatialService.get_climate_zone(lat, lon)
                    geo_data['climate_zone'] = climate_zone
                    
                    # Format geospatial context for Gemini
                    if geo_data:
                        geospatial_context = f"""

REAL-WORLD GEOSPATIAL DATA FOR THIS LOCATION:
{json.dumps(geo_data, indent=2)}

IMPORTANT: Use this real data to enhance your analysis accuracy:
- Weather data for climate-aware AC sizing
- NASA solar irradiance for accurate solar calculations
- Elevation for drainage and tilt optimization
- Sun position for optimal panel angles
- Climate zone for HVAC requirements
"""
                        print(f"DEBUG: Geospatial context added ({len(geo_data)} sources)")
                
                except Exception as e:
                    print(f"WARNING: Geospatial data fetch failed: {e}")
                    # Continue without geospatial data
            
            # ENHANCED: Fetch product intelligence for PRODUCT_SCAN journey
            product_context = ""
            if journey_id == 'PRODUCT_SCAN':
                try:
                    from app.services.product_intelligence_service import ProductIntelligenceService
                    
                    print(f"DEBUG: Fetching product intelligence data")
                    
                    # Get product intelligence
                    product_intel = ProductIntelligenceService.get_enhanced_product_context(
                        image_bytes,
                        user_answers.get('detected_category', 'unknown product')
                    )
                    
                    # Format product context for Gemini
                    if product_intel:
                        product_context = f"""

REAL-WORLD PRODUCT DATA:
{json.dumps(product_intel, indent=2)}

IMPORTANT: Use this verified data to enhance your analysis:
- If barcode detected, use exact product data from Open Food Facts (2.8M products)
- Use carbon database for verified CO₂ footprints (ADEME source)
- Use material database for recycling properties
- Cite sources for credibility (e.g., "ADEME 2023", "Open Food Facts")
"""
                        print(f"DEBUG: Product intelligence added (barcode: {product_intel.get('barcode_detected')})")
                
                except Exception as e:
                    print(f"WARNING: Product intelligence fetch failed: {e}")
                    # Continue without product data
            
            full_prompt = prompt_template + context + geospatial_context + product_context
            
            # Run analysis with timeout
            def _call_gemini():
                return model_analysis.generate_content([full_prompt, image])
            
            with concurrent.futures.ThreadPoolExecutor() as executor:
                future = executor.submit(_call_gemini)
                try:
                    response = future.result(timeout=90)  # 90 second timeout for analysis
                except concurrent.futures.TimeoutError:
                    print(f"ERROR: Gemini analysis for {journey_id} timed out after 90s")
                    raise Exception("Gemini API timeout")
            
            text = AIService._clean_json_text(response.text)
            result = json.loads(text)
            
            # Ensure journey is set
            result['journey'] = journey_id
            
            print(f"DEBUG: {journey_id} analysis complete")
            return result

        except Exception as e:
            print(f"Analysis Error for {journey_id}: {e}")
            return {
                "journey": journey_id,
                "product_name": "Analysis Error",
                "error": str(e),
                "recommendation": "Please try again with a clearer image"
            }

    @staticmethod
    def _clean_json_text(text: str) -> str:
        """Remove markdown code blocks from JSON response."""
        return text.replace("```json", "").replace("```", "").strip()
