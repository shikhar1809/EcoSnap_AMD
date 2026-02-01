import requests
import json

base_url = "http://localhost:8000"

def test_category(cat):
    print(f"Testing category: {cat}")
    try:
        r = requests.get(f"{base_url}/marketplace/products", params={"category": cat})
        print(f"Status: {r.status_code}")
        if r.status_code == 200:
            data = r.json()
            print(f"Products count: {len(data.get('products', []))}")
            # print(json.dumps(data, indent=2))
        else:
            print(r.text)
    except Exception as e:
        print(f"Error: {e}")
    print("-" * 20)

test_category("solar_equipment")
test_category("energy_efficient")
test_category("sustainable_products")
test_category("services")
test_category(None)
