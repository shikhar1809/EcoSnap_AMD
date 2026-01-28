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
    def analyze_with_gemini(image_bytes: bytes, detected_objects: list):
        """
        Sends image and detected tags to Gemini for detailed analysis.
        """
        try:
            # Extract just labels for the prompt context
            object_labels = [obj['label'] for obj in detected_objects]
            print(f"Analyzing with Gemini... Objects: {object_labels}")
            image = Image.open(io.BytesIO(image_bytes))
            
            prompt = f"""
            You are an expert home sustainability auditor and green architect for the Indian context.
            I have detected the following objects in this room: {", ".join(object_labels)}.
            
            Analyze the image and provide a JSON response with the following structure:
            {{
                "appliances": [
                    {{
                        "type": "Name of appliance (e.g. AC, Fridge)",
                        "brand": "Estimated brand or 'Unknown'",
                        "estimated_age": "Estimated age in years",
                        "efficiency_rating": "High/Medium/Low",
                        "current_power_consumption": "Estimated watts",
                        "recommended_replacement": "Name of a specific 5-star rated replacement model available in India (e.g. LG AI Convertible 6-in-1)",
                        "payback_period": "Time to recover cost via electricity savings (e.g. '1.5 years')",
                        "financial_savings_year": "Estimated ₹ savings per year",
                        "affiliate_link": "Generate a mock Flipkart/Amazon India link for the replacement model",
                        "e_waste_value": "Estimated scrap value in ₹"
                    }}
                ],
                "efficiency_score": "Integer 0-100 representing room energy efficiency",
                "recommendation": "One key actionable tip to improve energy efficiency in this specific room.",
                "green_architecture": {{
                    "layout_advice": "Specific advice on how to rearrange furniture or items for better natural light/airflow",
                    "sustainable_additions": "Suggestion for plants or sustainable materials to add"
                }}
            }}
            
            Return ONLY the JSON. Do not include markdown formatting like ```json.
            Prioritize recommendations with the shortest payback period.
            """
            
            response = model_gemini.generate_content([prompt, image])
            print(f"Gemini Raw Response: {response.text}")
            
            # Clean response if it contains markdown code blocks
            text = response.text.replace("```json", "").replace("```", "").strip()
            return json.loads(text)
            
        except Exception as e:
            print(f"Gemini Error: {e}")
            import traceback
            traceback.print_exc()
            # Fallback response
            return {
                "appliances": [],
                "efficiency_score": 0,
                "recommendation": f"Error: {str(e)}",
                "green_architecture": {
                    "layout_advice": "Could not generate advice.",
                    "sustainable_additions": "None"
                }
            }
