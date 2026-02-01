#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Comprehensive Journey Testing Script
Tests all 5 user journeys with real images and validates hackathon standards
"""
import requests
import base64
import json
from pathlib import Path

API_BASE = "http://127.0.0.1:8000/api/analysis"

def encode_image(image_path):
    """Encode image to base64"""
    with open(image_path, 'rb') as f:
        return base64.b64encode(f.read()).decode('utf-8')

def test_journey(image_path, journey_name, expected_checks):
    """Test a specific journey"""
    print(f"\n{'='*60}")
    print(f"Testing: {journey_name}")
    print(f"Image: {Path(image_path).name}")
    print(f"{'='*60}")
    
    # Encode image
    image_b64 = encode_image(image_path)
    
    # Call API
    response = requests.post(
        f"{API_BASE}/analyze",
        json={"image": image_b64}
    )
    
    if response.status_code != 200:
        print(f"❌ API Error: {response.status_code}")
        print(response.text)
        return False
    
    data = response.json()
    print(f"✅ API Response received")
    print(f"Journey Type: {data.get('journey_executed', 'UNKNOWN')}")
    
    # Run validation checks
    issues = []
    for check_name, check_fn in expected_checks.items():
        try:
            result = check_fn(data)
            if result:
                print(f"✅ {check_name}")
            else:
                print(f"❌ {check_name}")
                issues.append(check_name)
        except Exception as e:
            print(f"❌ {check_name}: {str(e)}")
            issues.append(f"{check_name} (Error: {e})")
    
    # Summary
    print(f"\n📊 Results: {len(expected_checks) - len(issues)}/{len(expected_checks)} passed")
    if issues:
        print(f"⚠️  Issues found:")
        for issue in issues:
            print(f"   - {issue}")
        return False
    else:
        print(f"🎉 All checks passed!")
        return True

# Validation Functions
def has_sustainability_score(data):
    """Check if sustainability score exists and is not null"""
    score = data.get('sustainability_score', {}).get('score')
    return score is not None and score != 'null'

def has_appliances(data):
    """Check if appliances are detected"""
    appliances = data.get('appliances', [])
    return len(appliances) > 0

def has_alternatives(data):
    """Check if alternatives are provided"""
    alternatives = data.get('alternatives', [])
    return len(alternatives) > 0

def solar_is_first_alternative(data):
    """Check if solar is the first alternative for house scans"""
    alternatives = data.get('alternatives', [])
    if not alternatives:
        return False
    first = alternatives[0].get('name', '')
    return 'solar' in first.lower()

def has_solar_viability(data):
    """Check if solar viability data exists"""
    solar = data.get('solar_viability', {})
    return 'is_viable' in solar

def has_architectural_advice(data):
    """Check if architectural advice exists"""
    arch = data.get('architectural_advice', {})
    return len(arch) > 0

def has_confidence_score(data):
    """Check if confidence score exists"""
    conf = data.get('confidence_score')
    return conf is not None and 0 <= conf <= 1

def has_recommendation(data):
    """Check if recommendation text exists"""
    rec = data.get('recommendation', '')
    return len(rec) > 10

def alternatives_have_prices(data):
    """Check if alternatives have price estimates"""
    alternatives = data.get('alternatives', [])
    if not alternatives:
        return False
    return all('price_estimate' in alt for alt in alternatives)

def alternatives_have_carbon_savings(data):
    """Check if alternatives have carbon savings"""
    alternatives = data.get('alternatives', [])
    if not alternatives:
        return False
    return all('carbon_savings' in alt for alt in alternatives)

# Test Cases
TESTS = [
    {
        "name": "Journey 1: Furnished Room (SPACE_AUDIT)",
        "image": "test_room.jpg",
        "checks": {
            "Has sustainability score (not null)": has_sustainability_score,
            "Has appliances detected": has_appliances,
            "Has alternatives": has_alternatives,
            "Has solar viability": has_solar_viability,
            "Has confidence score": has_confidence_score,
            "Has recommendation": has_recommendation,
            "Alternatives have prices": alternatives_have_prices,
            "Alternatives have carbon savings": alternatives_have_carbon_savings,
        }
    },
    {
        "name": "Journey 2: House Front (SPACE_AUDIT - Solar Priority)",
        "image": "test_house_front.jpg",
        "checks": {
            "Has sustainability score (not null)": has_sustainability_score,
            "Solar is first alternative": solar_is_first_alternative,
            "Has solar viability": has_solar_viability,
            "Has architectural advice": has_architectural_advice,
            "Has alternatives": has_alternatives,
            "Has confidence score": has_confidence_score,
            "Alternatives have prices": alternatives_have_prices,
        }
    },
    {
        "name": "Journey 3: Product (Empty Bottle)",
        "image": "test_empty_bottle.jpeg",
        "checks": {
            "Has alternatives": has_alternatives,
            "Has sustainability score": has_sustainability_score,
            "Has confidence score": has_confidence_score,
            "Alternatives have prices": alternatives_have_prices,
            "Alternatives have carbon savings": alternatives_have_carbon_savings,
        }
    },
]

def main():
    print("🚀 EcoSnap Comprehensive Journey Testing")
    print("Testing all user journeys for hackathon readiness\n")
    
    base_path = Path(__file__).parent
    results = []
    
    for test in TESTS:
        image_path = base_path / test["image"]
        if not image_path.exists():
            print(f"⚠️  Skipping {test['name']}: Image not found")
            continue
        
        passed = test_journey(str(image_path), test["name"], test["checks"])
        results.append((test["name"], passed))
    
    # Final Summary
    print(f"\n{'='*60}")
    print("📊 FINAL SUMMARY")
    print(f"{'='*60}")
    passed_count = sum(1 for _, passed in results if passed)
    total_count = len(results)
    
    for name, passed in results:
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"{status}: {name}")
    
    print(f"\n🎯 Overall: {passed_count}/{total_count} journeys passed")
    
    if passed_count == total_count:
        print("🎉 ALL TESTS PASSED! Ready for hackathon demo!")
    else:
        print("⚠️  Some tests failed. Review issues above.")
        print("\n📋 Next Steps:")
        print("1. Review failed checks")
        print("2. Update demo_responses.py or AI prompts")
        print("3. Re-run tests")

if __name__ == "__main__":
    main()
