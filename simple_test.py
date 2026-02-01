import requests
import base64

# Simple test
with open('test_room.jpg', 'rb') as f:
    img_b64 = base64.b64encode(f.read()).decode('utf-8')

response = requests.post('http://127.0.0.1:8000/scan', json={'image': img_b64})
print(f"Status: {response.status_code}")
print(f"Response: {response.json()}")
