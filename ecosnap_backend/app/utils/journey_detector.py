"""
Journey Detection Logic for EcoSnap
Determines which user journey to execute based on image analysis
"""

def detect_journey_from_gemini_response(gemini_text: str, image_description: str = "") -> str:
    """
    Detect journey type from Gemini's analysis
    
    Returns: SPACE_AUDIT, SPACE_PLANNING, FIND_ALTERNATIVE, or SPECIAL
    """
    text_lower = (gemini_text + " " + image_description).lower()
    
    # SPACE_AUDIT: House/Building exterior with solar potential
    house_keywords = ['house', 'building', 'roof', 'rooftop', 'exterior', 'facade', 'home exterior', 'residential']
    if any(keyword in text_lower for keyword in house_keywords):
        return "SPACE_AUDIT"
    
    # SPACE_PLANNING: Interior room (furnished or empty)
    room_keywords = ['room', 'interior', 'living room', 'bedroom', 'kitchen', 'office', 'furniture', 'ac', 'air conditioner']
    if any(keyword in text_lower for keyword in room_keywords):
        # Check if furnished or empty
        furnished_keywords = ['furniture', 'sofa', 'table', 'chair', 'appliance', 'ac', 'tv']
        if any(keyword in text_lower for keyword in furnished_keywords):
            return "SPACE_AUDIT"  # Furnished room = audit existing
        else:
            return "SPACE_PLANNING"  # Empty room = plan new
    
    # FIND_ALTERNATIVE: Specific products
    product_keywords = ['bottle', 'watch', 'phone', 'laptop', 'bag', 'shoes', 'clothing', 'electronics', 'plastic']
    if any(keyword in text_lower for keyword in product_keywords):
        return "FIND_ALTERNATIVE"
    
    # Default fallback
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
