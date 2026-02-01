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
model_triage = genai.GenerativeModel('gemini-2.0-flash')

# Deep Analysis: Comprehensive with Gemini 2.0 Flash (more reliable than thinking model)
model_analysis = genai.GenerativeModel('gemini-2.0-flash')

# Initialize YOLO for object detection
model_yolo = YOLO("yolov8n.pt")

# ============================================================
# JOURNEY-SPECIFIC PROMPT TEMPLATES
# Each journey returns ONLY its relevant fields
# ============================================================

JOURNEY_PROMPTS = {
    "SOLAR_AUDIT": """
You are EcoSnap's Solar Potential Analyzer. Analyze this property exterior image.

FOCUS ONLY ON:
1. Roof/terrace area estimation (sq.m)
2. Sunlight quality (direct/partial/shaded)
3. Shading issues (trees, buildings)
4. Optimal panel placement zones
5. Recommended solar capacity (kW)

OUTPUT JSON:
{{
    "journey": "SOLAR_AUDIT",
    "type": "property_exterior",
    "product_name": "Solar Potential Analysis",
    
    "solar_analysis": {{
        "viability_score": 0-100,
        "roof_area_sqm": number,
        "usable_area_sqm": number,
        "sunlight_quality": "Excellent/Good/Fair/Poor",
        "sunlight_hours": 5.2,
        "shading_issues": ["list of issues"],
        "optimal_orientation": "South/East/West",
        "recommended_capacity_kw": number
    }},
    
    "financials": {{
        "system_cost": number,
        "pm_surya_ghar_subsidy": number,
        "state_subsidy": number,
        "net_cost": number,
        "monthly_savings": number,
        "payback_months": number,
        "lifetime_savings_25yr": number
    }},
    
    "recommendation": "Main advice for this property",
    "confidence_score": 0.0-1.0
}}
""",

    "ROOM_ENERGY": """
You are EcoSnap's Room Energy Auditor. Analyze this room interior image.

FOCUS ONLY ON:
1. Detect appliances (AC, fans, lights, TV, fridge, etc.)
2. Estimate their efficiency (old/new, star rating guess)
3. Identify vampire power sources (standby devices)
4. Suggest efficiency upgrades with savings

DO NOT mention solar panels unless visible on the image.

OUTPUT JSON:
{{
    "journey": "ROOM_ENERGY",
    "type": "room_interior",
    "product_name": "Room Energy Audit",
    
    "efficiency_score": 0-100,
    
    "detected_appliances": [
        {{
            "name": "Appliance name",
            "type": "AC/Fan/Light/TV/Fridge/Other",
            "status": "efficient/average/inefficient",
            "estimated_power_watts": number,
            "estimated_star_rating": "1-5 or Unknown",
            "upgrade_suggestion": "Suggested replacement",
            "annual_savings_inr": number
        }}
    ],
    
    "vampire_power": {{
        "detected": true/false,
        "sources": ["TV standby", "Chargers"],
        "estimated_waste_watts": number,
        "annual_cost_inr": number
    }},
    
    "quick_wins": [
        {{"item": "LED bulb pack", "cost": 300, "annual_savings": 800}}
    ],
    
    "total_potential_savings_year": number,
    "recommendation": "Main advice for this room",
    "confidence_score": 0.0-1.0
}}
""",

    "PRODUCT_SCAN": """
You are EcoSnap's Product Lifecycle Analyzer. Analyze this consumer product.

FOCUS ONLY ON:
1. Identify the product (type, material, brand if visible)
2. Estimate carbon footprint (manufacturing, transport, disposal)
3. Material recyclability
4. Green alternatives with prices

DO NOT mention solar panels, rooms, or appliances.

OUTPUT JSON:
{{
    "journey": "PRODUCT_SCAN",
    "type": "product",
    "product_name": "Product description",
    "brand": "Brand if detected",
    
    "sustainability_grade": "A/B/C/D/F",
    
    "carbon_footprint": {{
        "total_grams_co2": number,
        "breakdown": {{
            "manufacturing": number,
            "transport": number,
            "packaging": number,
            "disposal": number
        }},
        "comparison_text": "Equivalent to X km car drive"
    }},
    
    "material_analysis": {{
        "primary_material": "Plastic/Glass/Metal/Fabric",
        "recyclability": "High/Medium/Low/None",
        "biodegradable": true/false,
        "microplastic_risk": true/false
    }},
    
    "alternatives": [
        {{
            "name": "Alternative product",
            "material": "Sustainable material",
            "price_estimate_inr": number,
            "carbon_reduction_percent": number,
            "payback_uses": number
        }}
    ],
    
    "circularity": {{
        "recyclable": true/false,
        "trade_in_value_inr": number,
        "disposal_advice": "How to properly dispose"
    }},
    
    "recommendation": "Main advice for this product",
    "confidence_score": 0.0-1.0
}}
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

THE 6 JOURNEYS (choose ONE):
1. SOLAR_AUDIT → House exterior, rooftop, building facade, terrace
2. ROOM_ENERGY → Furnished room with appliances (living room, office, bedroom)
3. PRODUCT_SCAN → Consumer product, bottle, gadget, clothing, packaging
4. BILL_OCR → Utility bill, electricity bill, receipt, document
5. FOOD_AUDIT → Food, meal, groceries, restaurant dish
6. VEHICLE_CHECK → Car, motorcycle, scooter, any vehicle
7. SPECIAL → Anything else

RULES:
- If you see a BUILDING EXTERIOR → SOLAR_AUDIT
- If you see a ROOM INTERIOR with furniture/appliances → ROOM_ENERGY
- If you see a SINGLE PRODUCT → PRODUCT_SCAN
- If you see TEXT/NUMBERS like a bill → BILL_OCR
- If you see FOOD → FOOD_AUDIT
- If you see a VEHICLE → VEHICLE_CHECK
- If unsure → SPECIAL

OUTPUT JSON:
{{
    "journey_id": "SOLAR_AUDIT|ROOM_ENERGY|PRODUCT_SCAN|BILL_OCR|FOOD_AUDIT|VEHICLE_CHECK|SPECIAL",
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
            
            response = model_triage.generate_content([prompt, image])
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
        journey_id = user_answers.get('journey_id', 'SPECIAL')
        print(f"DEBUG: Running {journey_id} analysis")
        
        try:
            image = Image.open(io.BytesIO(image_bytes))
            
            # Get journey-specific prompt
            prompt_template = JOURNEY_PROMPTS.get(journey_id, JOURNEY_PROMPTS['SPECIAL'])
            
            # Add user context if available
            context = f"\nUser provided context: {json.dumps(user_answers)}" if user_answers else ""
            full_prompt = prompt_template + context
            
            # Run analysis
            response = model_analysis.generate_content([full_prompt, image])
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
