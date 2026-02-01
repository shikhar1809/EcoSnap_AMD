import google.generativeai as genai
from ultralytics import YOLO
from PIL import Image
import io
import json
import os
from app.core.config import get_settings

settings = get_settings()

# Demo Mode: Set to True for hackathon demo with curated responses
DEMO_MODE = os.getenv("ECOSNAP_DEMO_MODE", "true").lower() == "true"

# Initialize Gemini Models
genai.configure(api_key=settings.GEMINI_API_KEY)

# Quick Scan: Fast triage with Gemini 2.0 Flash
model_gemini_quick = genai.GenerativeModel('gemini-2.0-flash')

# Deep Scan: Advanced analysis with Gemini 2.0 Flash Thinking
model_gemini_deep = genai.GenerativeModel('gemini-2.0-flash-thinking-exp-01-21')

# Initialize YOLO (will download weights on first run)
model_yolo = YOLO("yolov8n.pt") 

class AIService:
    @staticmethod
    def detect_objects(image_bytes: bytes):
        """
        Runs YOLOv8 locally for fast object detection.
        """
        try:
            image = Image.open(io.BytesIO(image_bytes))
            results = model_yolo(image)
            
            detected = []
            for result in results:
                for box in result.boxes:
                    class_id = int(box.cls[0])
                    class_name = model_yolo.names[class_id]
                    conf = float(box.conf[0])
                    detected.append({"name": class_name, "confidence": conf})
            
            return detected
        except Exception as e:
            print(f"YOLO Error: {e}")
            return []

    @staticmethod
    def generate_questions(image_bytes: bytes, detected_objects: list, user_note: str = None):
        """
        Smart Triage System:
        Analyzes the image to trigger one of 5 specific user journeys.
        """
        try:
            image = Image.open(io.BytesIO(image_bytes))
            
            # Context string only if objects exist or note is present
            context_str = f"User Note: {user_note}" if user_note else ""
            if detected_objects:
                context_str += f". Detected Objects: {', '.join([d['name'] for d in detected_objects])}"

            prompt = f"""
            You are the "EcoSnap Triage Brain". Your job is to classify this image into ONE of 5 Journeys.

            CONTEXT: {context_str}

            THE 5 JOURNEYS:
            1. 'FIND_ALTERNATIVE' -> Standard items (bottles, gadgets, clothes, food). User wants carbon footprint & green alternatives.
            2. 'SPACE_AUDIT' -> A FURNISHED room or workspace (messy, active, has appliances). User wants to lower footprint/cost of existing space.
            3. 'SPACE_PLANNING' -> An EMPTY room, bare shell, or construction site. User wants to plan a new green workspace/room.
            4. 'BILL_ANALYSIS' -> A document, invoice, or electricity bill. User wants forensic bill analysis and cost-cutting info.
            5. 'SPECIAL' -> If 'User Note' is very specific/unique (e.g., "Help me fix this specific broken part") OR if image doesn't fit others.

            OUTPUT JSON ONLY:
            {{
                "journey_id": "FIND_ALTERNATIVE" | "SPACE_AUDIT" | "SPACE_PLANNING" | "BILL_ANALYSIS" | "SPECIAL",
                "confidence": 0.0-1.0,
                "reasoning": "Why you chose this journey.",
                "verification": {{
                    "detected_category": "Short Name (e.g. Empty Room, Old AC, Bill)",
                    "question": "Asking the user to confirm the intent (e.g. 'I see an empty room. Do you want to plan a Green Workspace?')"
                }},
                "questions": [
                    {{ "id": "q1", "text": "Deep forensic question 1 related to the journey" }},
                    {{ "id": "q2", "text": "Deep forensic question 2 related to the journey" }},
                    {{ "id": "q3", "text": "Deep forensic question 3 related to the journey" }}
                ]
            }}
            """
            
            # Use quick model for fast triage
            response = model_gemini_quick.generate_content([prompt, image])
            text = AIService._clean_json_text(response.text)
            print(f"DEBUG: Triage Response: {text}")
            return json.loads(text)

        except Exception as e:
            print(f"Gemini Triage Error: {e}")
            # Fallback safe response
            return {
                "journey_id": "SPECIAL",
                "confidence": 0.3,
                "verification": {"detected_category": "Unknown", "question": "What would you like to analyze?"},
                "questions": []
            }
    
    @staticmethod
    def get_confidence_level(score: float) -> str:
        """Return human-readable confidence level."""
        if score >= 0.8:
            return "High Confidence"
        elif score >= 0.6:
            return "Moderate Confidence"
        else:
            return "Low Confidence - Please verify"

    @staticmethod
    def analyze_with_gemini(image_bytes: bytes, detected_objects: list, user_answers: dict):
        """
        Perform Deep Forensic Analysis based on the specific Journey ID.
        Uses curated demo responses in DEMO_MODE for reliable hackathon demos.
        """
        # Extract journey_id first
        journey_id = user_answers.get('journey_id', 'FIND_ALTERNATIVE')
        print(f"DEBUG: Running Analysis for Journey: {journey_id}, DEMO_MODE: {DEMO_MODE}")
        
        # DEMO MODE: Return curated, accurate responses
        if DEMO_MODE:
            try:
                from app.data.demo_responses import get_demo_response
                demo_data = get_demo_response(journey_id)
                print(f"DEBUG: Returning curated demo response for {journey_id}")
                return demo_data
            except ImportError as e:
                print(f"DEBUG: Demo responses not available, falling back to AI: {e}")
        
        try:
            image = Image.open(io.BytesIO(image_bytes))
            
            # Extract info
            answers_context = json.dumps(user_answers)
            object_labels = [d['name'] for d in detected_objects]
            
            print(f"DEBUG: AI Analysis for Journey: {journey_id}")

            prompt = f"""
            You are EcoSnap's Forensic Sustainability Engine.
            JOURNEY MODE: {journey_id}
            User Inputs/Context: {answers_context}
            YOLO Objects: {", ".join(object_labels)}.
            
            TASK: Perform a deep lifecycle assessment (LCA), FINANCIAL AUDIT, and TRUST CHECK tailored to the Journey.
            
            JOURNEY SPECIFIC INSTRUCTIONS:
            
            1. IF 'FIND_ALTERNATIVE' (Product):
               - Focus on "Alternatives", "Material Breakdown", "Carbon Footprint".
               - Economics: Calculate Lifetime Savings of switching to the Green Alternative.

            2. IF 'SPACE_AUDIT' (Furnished Room):
               - Focus on "Appliances", "Vampire Power", "Lighting Efficiency".
               - Economics: Calculate MONTHLY savings if they optimize this specific room.
            
            3. IF 'SPACE_PLANNING' (Empty Room):
               - Focus on "Solar Potential", "Green Materials", "Layout Optimization".
               - Economics: Estimated Budget for a "Green Setup" vs "Standard Setup".
            
            4. IF 'BILL_ANALYSIS' (Document):
               - OCR the bill (simulated). Find tariffs, consumption.
               - Recommendation: Specific behaviors to cut THIS bill.
            
            REQUIRED CALCULATIONS (All Journeys):
            - **PAYBACK TIMER**: Estimate monthly savings vs cost.
            - **TRUST DATA**: User trust score, verified stats.
            
            OUTPUT FORMAT (JSON ONLY):
            {{
                "type": "product_or_room", 
                "journey_executed": "{journey_id}",
                "product_name": "Headline Name",
                "category": "Category",
                "data_source": "AI Forensic Estimates",
                "condition_assessment": "Condition description",
                
                "economics": {{
                    "upfront_cost": "Cost of upgrade/action",
                    "monthly_savings": "Value",
                    "payback_period_months": 12,
                    "five_year_savings": "Value",
                    "is_investment": true,
                    "message": "Investment message."
                }},

                "trust_data": {{
                    "score": 4.8,
                    "total_ratings": 1420,
                    "verified_homes": 847,
                    "satisfaction_rate": "98%"
                }},

                "social_proof": {{
                    "neighbors_upgraded": 41,
                    "area_trend": "High Adoption",
                    "top_installer": {{ "name": "Raj Kumar", "rating": 4.9, "jobs": 23 }}
                }},

                "guarantees": {{
                    "warranty": "Standard Warranty",
                    "performance": "Performance Guarantee",
                    "risk_free": "Risk Free Clause"
                }},

                "carbon_footprint": {{ "total_kg_co2": "Val", "comparison_text": "Text", "breakdown": {{ "manufacturing": "x", "transport": "y", "use_phase": "z", "end_of_life": "a" }} }},
                
                "material_breakdown": [
                    {{"component": "Part", "material": "Material", "recyclability": "High/Low"}}
                ],
                
                "sustainability_score": {{ 
                    "score": "0-100", 
                    "grade": "A-F", 
                    "reason": "Why?",
                    "shareable_text": "Social Caption" 
                }},
                
                "solar_viability": {{
                    "is_viable": true/false,
                    "potential_kw": "1.5kW",
                    "sunlight_quality": "Direct/Partial",
                    "recommendation": "Rec"
                }},
                
                "architectural_advice": {{
                    "layout_optimization": "Advice",
                    "ventilation_tip": "Advice"
                }},

                "alternatives": [
                    {{"name": "Item", "price_estimate": "Price", "benefit": "Benefit", "carbon_savings": "Savings"}}
                ],
                
                "appliances": [
                     {{"type": "Old Fan", "current_power": "80W", "replacement": "BLDC Fan (28W)", "savings_yr": "₹1500"}}
                ],

                "recommendation": "Main advice.",
                "recovery_info": {{ "recycling_time": "Time", "recovery_value_inr": "Value", "recycling_action": "Action" }}
            }}
            """
            
            # Use deep thinking model for comprehensive forensic analysis
            response = model_gemini_deep.generate_content([prompt, image])
            text = AIService._clean_json_text(response.text)
            print(f"DEBUG: Analysis Response: {text}")
            return json.loads(text)
            
        except Exception as e:
            print(f"Gemini Analysis Error: {e}")
            return {
                "product_name": "Analysis Failed",
                "condition_assessment": f"Error: {str(e)[:50]}...",
                "sustainability_score": {"grade": "N/A"},
                "economics": {"payback_period_months": 0}
            }

    @staticmethod
    def _clean_json_text(text):
        return text.replace("```json", "").replace("```", "").strip()
