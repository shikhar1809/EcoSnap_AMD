import requests
import base64
import json

# Test with room image
with open('test_room.jpg', 'rb') as f:
    img_b64 = base64.b64encode(f.read()).decode('utf-8')

print("Testing API endpoint...")
response = requests.post('http://127.0.0.1:8000/api/analysis/analyze', json={'image': img_b64})
print(f"Status Code: {response.status_code}")
print(f"Response Keys: {list(response.json().keys())}")
print(f"\nFull Response:")
print(json.dumps(response.json(), indent=2))
