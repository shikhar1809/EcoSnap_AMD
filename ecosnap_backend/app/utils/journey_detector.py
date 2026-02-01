"""
Journey Detection Logic for EcoSnap
Determines which user journey to execute based on image analysis
"""

def detect_journey_from_gemini_response(gemini_response: any, image_description: str = "") -> str:
    """
    Detect journey type from Gemini's analysis.
    Now 10/10 AI Powered: Trusts the JSON output from the 'Brain' directly.
    """
    # If the input is already a dictionary (from JSON), use it directly
    if isinstance(gemini_response, dict):
        return gemini_response.get("journey_id", "SPECIAL")
    
    # Fallback for old string-based calls (legacy)
    text_lower = str(gemini_response).lower()
    
    # SPACE_AUDIT maps to SOLAR_AUDIT in our new system
    if "solar_audit" in text_lower or "space_audit" in text_lower: return "SOLAR_AUDIT"
    if "room_audit" in text_lower: return "ROOM_AUDIT"
    if "space_planning" in text_lower: return "SPACE_PLANNING"
    if "find_alternative" in text_lower: return "FIND_ALTERNATIVE"
    
    return "SPECIAL"


def detect_product_category(gemini_text: str) -> str:
    """
    Map detected objects to Fake Store API categories
    
    Returns: electronics, clothing, bottle, or default
    """
    text_lower = gemini_text.lower()
    
    # Electronics
    if any(word in text_lower for word in ['watch', 'phone', 'laptop', 'computer', 'electronics', 'gadget']):
        return 'electronics'
    
    # Clothing
    if any(word in text_lower for word in ['shirt', 'shoes', 'clothing', 'apparel', 'fashion']):
        return 'clothing'
    
    # Bottle (special case)
    if 'bottle' in text_lower:
        return 'bottle'
    
    # Default
    return 'electronics'
