import requests
import json

BASE_URL = "http://localhost:8000"

def test_scancarbon():
    print("Testing ScanCarbon (AI Analysis)...")
    
    # Create a dummy image (1x1 pixel)
    # In a real test we would use a real image, but for checking schema pass-through this works 
    # if the AI handles garbage or we mock it. 
    # Wait, the AI service will try to open it with PIL.
    # Let's use a minimal valid PNG.
    
    minimal_png = (
        b'\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89'
        b'\x00\x00\x00\nIDATx\x9cc\x00\x01\x00\x00\x05\x00\x01\r\n-\xb4\x00\x00\x00\x00IEND\xaeB`\x82'
    )
    
    files = {'files': ('test.png', minimal_png, 'image/png')}
    data = {'budget': 'Unlimited'}
    
    try:
        res = requests.post(f"{BASE_URL}/analysis/analyze", files=files, data=data)
        print(f"Status Code: {res.status_code}")
        
        if res.status_code == 200:
            resp_json = res.json()
            print("Response Keys:", resp_json.keys())
            
            # Check for new ScanCarbon keys
            required_keys = ["product_name", "carbon_footprint", "material_breakdown", "sustainability_score"]
            missing = [k for k in required_keys if k not in resp_json]
            
            if not missing:
                print("SUCCESS: All ScanCarbon keys present.")
                print("Product:", resp_json.get("product_name"))
                print("Score:", resp_json.get("sustainability_score"))
            else:
                print(f"FAILED: Missing keys: {missing}")
                print("Full Response:", json.dumps(resp_json, indent=2))
        else:
            print("Error Response:", res.text)
            
    except Exception as e:
        print(f"Exception: {e}")

if __name__ == "__main__":
    test_scancarbon()
