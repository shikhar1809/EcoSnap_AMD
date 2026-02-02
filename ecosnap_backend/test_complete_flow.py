"""
Test correct endpoint path
"""
import requests

print("Testing CORRECT backend path...")

# Test context endpoint first
files = {'files': ('test.jpg', open('C:/Users/royal/.gemini/antigravity/brain/ee5f3f3b-7ff7-4d21-9b7b-5a8b21a61ab9/uploaded_media_1769966287375.png', 'rb'), 'image/png')}
data = {
    'scan_mode': 'quick'
}

try:
    response = requests.post(
        'http://localhost:8000/analysis/analyze/context',
        files=files,
        data=data,
        timeout=30
    )
    
    print(f"Context Status: {response.status_code}")
    if response.status_code == 200:
        result = response.json()
        print(f"Journey: {result.get('journey_id')}")
        print(f"Confidence: {result.get('confidence')}")
        
        # Now test analyze endpoint
        files2 = {'files': ('test.jpg', open('C:/Users/royal/.gemini/antigravity/brain/ee5f3f3b-7ff7-4d21-9b7b-5a8b21a61ab9/uploaded_media_1769966287375.png', 'rb'), 'image/png')}
        data2 = {
            'user_responses': '{"journey_id": "' + result.get('journey_id', 'PRODUCT_SCAN') + '"}',
            'demo_mode': 'true'
        }
        
        response2 = requests.post(
            'http://localhost:8000/analysis/analyze',
            files=files2,
            data=data2,
            timeout=30
        )
        
        print(f"\nAnalyze Status: {response2.status_code}")
        if response2.status_code == 200:
            print("SUCCESS! Analysis works!")
            print(f"Keys: {list(response2.json().keys())}")
        else:
            print(f"Error: {response2.text[:500]}")
    else:
        print(f"Context Error: {response.text[:500]}")
    
except Exception as e:
    print(f"ERROR: {e}")
