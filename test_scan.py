import requests
import os

BASE_URL = "http://localhost:8000"
TEST_IMAGE_PATH = r"c:\Users\royal\Desktop\Resources\Projects\EcoSnap\test_house_front.jpg"

def test_scan():
    print(f"Testing Scan with: {TEST_IMAGE_PATH}")
    
    if not os.path.exists(TEST_IMAGE_PATH):
        print("Error: Test image not found at specified path.")
        return

    try:
        with open(TEST_IMAGE_PATH, "rb") as f:
            files = {"files": ("test_house_front.jpg", f, "image/jpeg")}
            print("Sending request to /analysis/analyze/context...")
            res = requests.post(f"{BASE_URL}/analysis/analyze/context", files=files)
            
            print(f"Status Code: {res.status_code}")
            if res.status_code == 200:
                data = res.json()
                print("\n--- Smart Triage Response ---")
                print(f"Analysis Type: {data.get('analysis_type')}")
                print(f"Detected Items: {data.get('detected_items')}")
                print(f"Confidence: {data.get('confidence')}")
                print(f"Questions: {len(data.get('questions', []))}")
                for q in data.get('questions', []):
                    print(f" - {q}")
            else:
                print(f"Error Response: {res.text}")
                
    except Exception as e:
        print(f"Exception: {e}")

if __name__ == "__main__":
    test_scan()
