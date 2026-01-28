import google.generativeai as genai
from ultralytics import YOLO
from PIL import Image
import io
import json
from app.core.config import get_settings

settings = get_settings()

# Initialize Gemini
genai.configure(api_key=settings.GEMINI_API_KEY)
model_gemini = genai.GenerativeModel('gemini-2.0-flash')

# Initialize YOLO (will download weights on first run)
model_yolo = YOLO("yolov8n.pt") 

class AIService:
    @staticmethod
    def detect_objects(image_bytes: bytes):
        """
        Runs YOLOv8 detection on the image bytes.
        Returns a list of detected objects with bounding boxes.
        """
        try:
            image = Image.open(io.BytesIO(image_bytes))
            results = model_yolo(image)
            
            detected_objects = []
            for result in results:
                for box in result.boxes:
                    class_id = int(box.cls[0])
                    class_name = model_yolo.names[class_id]
                    confidence = float(box.conf[0])
                    
                    # Get normalized coordinates (x1, y1, x2, y2)
                    # box.xyxyn returns a tensor, we need to convert to list
                    coords = box.xyxyn[0].tolist() 
                    
                    if confidence > 0.3: # Filter low confidence
                        detected_objects.append({
                            "label": class_name,
                            "box": coords, # [x1, y1, x2, y2] normalized 0-1
                            "confidence": confidence
                        })
            
            return detected_objects
        except Exception as e:
            print(f"YOLO Error: {e}")
            import traceback
            traceback.print_exc()
            return []

    @staticmethod
    def generate_questions(image_bytes: bytes, detected_objects: list):
        """
        scans image, determines type, and generates 3 relevant questions.
        """
        try:
            object_labels = [obj['label'] for obj in detected_objects]
            image = Image.open(io.BytesIO(image_bytes))
            
            prompt = f"""
            You are EcoSnap. Analyze this image (Objects: {", ".join(object_labels)}).
            
            Determine if it is a "Product" or "Room".
            
            Generate 3 INTELLIGENT, FORENSIC questions.
            - IF MULTIPLE ITEMS: Ask "I see multiple items (Item A, Item B), which one are you analyzing?"
            - IF BROKEN/OLD: Ask "It looks worn out. Are you planning to repair or replace it?"
            - IF PRODUCT: Ask "How long have you owned this?" or "What is your goal (sell/recycle)?"
            - IF ROOM: Ask "Are you renovating or just auditing for bills?"
            
            Return JSON:
            {{
                "type": "room/product",
                "questions": [
                    {{"id": "q1", "text": "Question?", "type": "text/number/select", "options": ["opt1", "opt2"] }} 
                ]
            }}
            (Max 3 questions).
            """
            response = model_gemini.generate_content([prompt, image])
            text = response.text.replace("```json", "").replace("```", "").strip()
            return json.loads(text)
        except Exception as e:
            print(f"Question Gen Error: {e}")
            return {
                "type": "product", 
                "questions": [
                    {"id": "budget", "text": "What is your budget?", "type": "text", "options": []}
                ]
            }

    @staticmethod
    def analyze_with_gemini(image_bytes: bytes, detected_objects: list, user_responses: dict):
        """
        Sends image + user answers to Gemini for detailed analysis.
        Uses ReferenceDatabase for verified ground truth if available.
        """
        try:
            from app.services.reference_data import ReferenceDatabase
            import json
            
            object_labels = [obj['label'] for obj in detected_objects]
            print(f"Analyzing with Gemini... Objects: {object_labels}")
            image = Image.open(io.BytesIO(image_bytes))
            
            # Check for Verified Data
            ref_match = ReferenceDatabase.get_data(detected_objects)
            ref_context = ""
            if ref_match:
                ref_context = (
                    f"CRITICAL: We have VERIFIED DATABASE DATA for this item ('{ref_match['matched_key']}'). "
                    f"Use these EXACT values for carbon/materials/recovery: {json.dumps(ref_match['data'])}. "
                    "Mark 'data_source' as 'Verified (Local DB)'."
                )
            
            context_str = "\n".join([f"- {k}: {v}" for k,v in user_responses.items()])
            
            prompt = f"""
            You are 'EcoSnap'.
            User Context Inputs: {context_str}
            Objects detected: {", ".join(object_labels)}.
            
            {ref_context}
            
            STEP 1: Classify (Room vs Product).
            STEP 2: Analyze FORENSICALLY.
            - Look for WEAR & TEAR (scratches, damage).
            - Look for MULTIPLE ITEMS (if yes, list them).
            - Estimate LIFESPAN based on condition.
            
            [IF PRODUCT]
            Return JSON:
            {{
                "type": "product",
                "product_name": "Name",
                "category": "Cat",
                "data_source": "Verified (Local DB) OR AI Estimate",
                "condition_assessment": "Excellent/Good/Fair/Poor",
                "estimated_lifespan": "e.g. 2 more years",
                "multiple_items_detected": ["Item 1", "Item 2"], 
                "carbon_footprint": {{ "total_kg_co2": "Val", "breakdown": {{ "manufacturing": "Val", "transport": "Val", "use_phase": "Val", "end_of_life": "Val" }}, "comparison_text": "text" }},
                "material_breakdown": [ {{ "component": "Part", "material": "Mat", "recyclability": "High/Med" }} ],
                "recovery_info": {{ "recycling_time": "Time", "recovery_value_inr": "Val", "recycling_action": "Action" }},
                "sustainability_score": {{ "score": "0-10", "grade": "A-F", "reason": "Reason" }},
                "alternatives": [ {{ "name": "Name", "carbon_savings": "Msg", "price_estimate": "Price", "benefit": "Msg" }} ],
                "recommendation": "Smart Advice: Repair/Replace? Buy New? (Based on condition)"
            }}
            
            [IF ROOM]
            Return JSON:
            {{
                "type": "room",
                "product_name": "Room Scan",
                "data_source": "AI Estimate",
                "efficiency_score": "0-100",
                "appliances": [ {{ "type": "Appliance", "brand": "Brand", "efficiency_rating": "High/Low", "estimated_age": "Years", "current_power_consumption": "Watts", "recommended_replacement": "Model", "financial_savings_year": "₹Val", "payback_period": "Years" }} ],
                "green_architecture": {{ "layout_advice": "Advice considering user goal", "sustainable_additions": "Additions" }},
                "recommendation": "Recommendation based on user budget/goal"
            }}
            
            Return ONLY JSON.
            """
            
            response = model_gemini.generate_content([prompt, image])
            text = response.text.replace("```json", "").replace("```", "").strip()
            return json.loads(text)
            
        except Exception as e:
            print(f"Gemini Error: {e}")
            return {
                "type": "product",
                "product_name": "Error Analyzing",
                "recommendation": str(e),
                "appliances": [],
                "carbon_footprint": {"total_kg_co2": "N/A"}, 
                "material_breakdown": []
            }
