"""
Quick test to see if backend analysis endpoint works
"""
import requests

print("Testing backend analysis endpoint...")

# Test with demo mode
files = {'files': ('test.jpg', b'fake_image_data', 'image/jpeg')}
data = {
    'user_responses': '{"journey_id": "PRODUCT_SCAN"}',
    'demo_mode': 'true'
}

try:
    response = requests.post(
        'http://localhost:8000/api/analysis/analyze',
        files=files,
        data=data,
        timeout=10
    )
    
    print(f"Status: {response.status_code}")
    print(f"Response: {response.json()}")
    
except Exception as e:
    print(f"ERROR: {e}")
