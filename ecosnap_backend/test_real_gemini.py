"""
Test REAL Gemini analysis (not demo mode)
"""
import requests

print("Testing REAL Gemini Analysis...")
print("="*70)

# Use real image
files = {'files': ('test.png', open('C:/Users/royal/.gemini/antigravity/brain/ee5f3f3b-7ff7-4d21-9b7b-5a8b21a61ab9/uploaded_media_1769966287375.png', 'rb'), 'image/png')}
data = {
    'user_responses': '{"journey_id": "PRODUCT_SCAN"}',
    'demo_mode': 'false'  # REAL analysis
}

try:
    print("Calling /analysis/analyze with demo_mode=false...")
    response = requests.post(
        'http://localhost:8000/analysis/analyze',
        files=files,
        data=data,
        timeout=120  # 2 minutes for Gemini
    )
    
    print(f"\nStatus: {response.status_code}")
    
    if response.status_code == 200:
        result = response.json()
        print(f"\n✅ SUCCESS! Real Gemini analysis works!")
        print(f"\nJourney: {result.get('journey')}")
        print(f"Product: {result.get('product_name')}")
        print(f"Confidence: {result.get('confidence_score')}")
        print(f"\nMetadata:")
        metadata = result.get('_metadata', {})
        print(f"  Demo Mode: {metadata.get('demo_mode')}")
        print(f"  APIs Called: {metadata.get('apis_called')}")
        print(f"  Data Sources: {len(metadata.get('data_sources_used', []))}")
        
        print(f"\nAll response keys: {list(result.keys())[:10]}...")
    else:
        print(f"\n❌ ERROR: {response.status_code}")
        print(f"Response: {response.text[:500]}")
    
except Exception as e:
    print(f"\n❌ EXCEPTION: {e}")

print("\n" + "="*70)
