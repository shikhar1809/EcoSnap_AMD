"""
Quick test to see if backend analysis endpoint works for WIND_ANALYSIS
"""
import requests
import json

print("Testing backend analysis endpoint for WIND_ANALYSIS...")

# Test with forced journey
files = {'files': ('test.jpg', b'fake_image_data', 'image/jpeg')}
user_responses = json.dumps({"journey_id": "WIND_ANALYSIS"})
data = {
    'user_responses': user_responses,
    'demo_mode': 'false' 
}

try:
    response = requests.post(
        'http://localhost:8000/analysis/analyze',
        files=files,
        data=data,
        timeout=60
    )
    
    print(f"Status: {response.status_code}")
    result = response.json()
    print(f"Journey: {result.get('journey')}")
    print(f"Financials keys: {result.get('financial_analysis', {}).keys()}")
    print(f"Installation keys: {result.get('installation_feasibility', {}).keys()}")
    # print(json.dumps(result, indent=2))
    
except Exception as e:
    print(f"ERROR: {e}")
