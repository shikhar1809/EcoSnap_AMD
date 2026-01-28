import requests
import json

BASE_URL = "http://localhost:8000"

def test_community():
    print("Testing Community...")
    # Post Question
    q = {
        "user_id": "test_user", "user_name": "Tester", 
        "title": "Test Q", "content": "Content", "category": "General"
    }
    res = requests.post(f"{BASE_URL}/community/questions", json=q)
    print(f"Post Question: {res.status_code}")
    
    # List Questions
    res = requests.get(f"{BASE_URL}/community/questions")
    print(f"List Questions: {res.status_code}, Count: {len(res.json())}")

def test_subsidies():
    print("\nTesting Subsidies...")
    # List Schemes
    res = requests.get(f"{BASE_URL}/subsidies/schemes")
    print(f"List Schemes: {res.status_code}, Count: {len(res.json())}")
    
    # Apply
    app = {
        "user_id": "test_user", "scheme_id": "ujala-ac",
        "appliance_details": "AC", "user_income_bracket": "Low"
    }
    res = requests.post(f"{BASE_URL}/subsidies/apply", json=app)
    print(f"Apply Subsidy: {res.status_code}, Status: {res.json().get('status')}")

def test_predictive():
    print("\nTesting Predictive AI...")
    data = {
        "appliance_type": "AC", "age_years": 5, "usage_hours_daily": 10,
        "brand": "Voltas", "last_serviced_months_ago": 12
    }
    res = requests.post(f"{BASE_URL}/predictive/analyze", json=data)
    print(f"Predictive Analyze: {res.status_code}")
    print(res.json())

def test_carbon():
    print("\nTesting Carbon Credits...")
    # Earn
    res = requests.post(f"{BASE_URL}/carbon/earn?user_id=test_user&co2_saved_kg=200")
    print(f"Earn Credits: {res.status_code}, Balance: {res.json().get('new_balance')}")
    
    # Trade (Buy)
    trade = {"user_id": "test_user", "amount": 1, "action": "BUY"}
    res = requests.post(f"{BASE_URL}/carbon/trade", json=trade)
    print(f"Buy Credits: {res.status_code}, Balance: {res.json().get('new_balance')}")

if __name__ == "__main__":
    try:
        test_community()
        test_subsidies()
        test_predictive()
        test_carbon()
        print("\nALL TESTS COMPLETED")
    except Exception as e:
        print(f"\nTEST FAILED: {e}")
