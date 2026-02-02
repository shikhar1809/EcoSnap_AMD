"""
Test Deep Analysis Flow
Tests the complete analysis pipeline
"""
import requests
import json
from pathlib import Path

# Test image (create a simple test)
print("="*70)
print("TESTING DEEP ANALYSIS FLOW")
print("="*70)

# Test 1: Health Check
print("\n1. Testing Backend Health...")
try:
    response = requests.get("http://localhost:8000/health")
    if response.status_code == 200:
        print(f"   ✅ Backend is running: {response.json()}")
    else:
        print(f"   ❌ Backend health check failed: {response.status_code}")
        exit(1)
except Exception as e:
    print(f"   ❌ Cannot connect to backend: {e}")
    print("   Make sure backend is running on localhost:8000")
    exit(1)

# Test 2: Context Analysis (Triage)
print("\n2. Testing Context Analysis (Triage)...")
try:
    # Create a dummy image file
    test_image = b"fake_image_data_for_testing"
    
    files = {'files': ('test.jpg', test_image, 'image/jpeg')}
    data = {
        'user_note': 'Test scan',
        'scan_mode': 'deep'
    }
    
    response = requests.post(
        "http://localhost:8000/api/analysis/analyze/context",
        files=files,
        data=data
    )
    
    if response.status_code == 200:
        result = response.json()
        print(f"   ✅ Triage successful")
        print(f"   Journey: {result.get('journey_id')}")
        print(f"   Confidence: {result.get('confidence')}")
        print(f"   Questions: {len(result.get('questions', []))}")
    else:
        print(f"   ❌ Triage failed: {response.status_code}")
        print(f"   Error: {response.text}")
except Exception as e:
    print(f"   ❌ Triage error: {e}")

# Test 3: Deep Analysis
print("\n3. Testing Deep Analysis...")
try:
    test_image = b"fake_image_data_for_testing"
    
    files = {'files': ('test.jpg', test_image, 'image/jpeg')}
    
    # Simulate user responses
    user_responses = {
        'journey_id': 'PRODUCT_SCAN',
        'detected_category': 'plastic bottle',
        'location': {
            'latitude': 19.0760,
            'longitude': 72.8777
        }
    }
    
    data = {
        'user_responses': json.dumps(user_responses)
    }
    
    response = requests.post(
        "http://localhost:8000/api/analysis/analyze",
        files=files,
        data=data,
        timeout=120  # 2 minute timeout
    )
    
    if response.status_code == 200:
        result = response.json()
        print(f"   ✅ Deep analysis successful")
        print(f"   Journey: {result.get('journey')}")
        print(f"   Message: {result.get('message')}")
        
        # Check for geospatial data
        if 'product_name' in result:
            print(f"   Product: {result.get('product_name')}")
        
        print(f"\n   Response keys: {list(result.keys())}")
    else:
        print(f"   ❌ Deep analysis failed: {response.status_code}")
        print(f"   Error: {response.text[:500]}")
except Exception as e:
    print(f"   ❌ Deep analysis error: {e}")

print("\n" + "="*70)
print("TEST COMPLETE")
print("="*70)
