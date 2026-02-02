"""
Test script for Google APIs integration
Tests Solar API, Weather API, and Maps API
"""
import sys
sys.path.append('.')

from app.services.google_api_service import GoogleAPIService

# Test coordinates (Mumbai, India)
TEST_LAT = 19.0760
TEST_LON = 72.8777

print("=" * 60)
print("TESTING GOOGLE APIs INTEGRATION")
print("=" * 60)

# Test 1: OpenWeatherMap API
print("\n1. Testing OpenWeatherMap API...")
print(f"   Location: {TEST_LAT}, {TEST_LON}")
weather = GoogleAPIService.get_weather_data(TEST_LAT, TEST_LON)
if weather:
    print(f"   [SUCCESS]")
    print(f"   Temperature: {weather['temperature']}C")
    print(f"   Humidity: {weather['humidity']}%")
    print(f"   Weather: {weather['weather']}")
    print(f"   City: {weather['city']}")
else:
    print("   [FAILED] - No data returned")

# Test 2: Google Maps Geocoding API
print("\n2. Testing Google Maps Geocoding API...")
location = GoogleAPIService.get_location_context(TEST_LAT, TEST_LON)
if location:
    print(f"   [SUCCESS]")
    print(f"   City: {location.get('city')}")
    print(f"   State: {location.get('state')}")
    print(f"   Address: {location.get('formatted_address')}")
else:
    print("   [FAILED] - No data returned")

# Test 3: Google Solar API
print("\n3. Testing Google Solar API...")
solar = GoogleAPIService.get_solar_potential(TEST_LAT, TEST_LON)
if solar:
    print(f"   [SUCCESS]")
    print(f"   Roof Area: {solar['roof_area_sqm']} sqm")
    print(f"   Annual Sun Hours: {solar['annual_sun_hours']}")
    print(f"   Panel Configs: {len(solar['panel_configs'])} available")
else:
    print("   [FAILED] - No data returned")
    print("   Note: Solar API may not have data for all locations")

# Test 4: Combined Enhanced Context
print("\n4. Testing Combined Enhanced Context...")
context = GoogleAPIService.get_enhanced_context(TEST_LAT, TEST_LON)
print(f"   Solar API Active: {context['has_solar_api']}")
print(f"   Weather API Active: {context['has_weather_api']}")
print(f"   Maps API Active: {context['has_maps_api']}")

print("\n" + "=" * 60)
print("TEST COMPLETE")
print("=" * 60)

# Summary
print("\nSUMMARY:")
success_count = sum([
    context['has_weather_api'],
    context['has_maps_api'],
    context['has_solar_api']
])
print(f"APIs Working: {success_count}/3")
if success_count == 3:
    print("STATUS: ALL SYSTEMS GO!")
elif success_count >= 2:
    print("STATUS: PARTIAL - Most APIs working")
else:
    print("STATUS: ISSUES - Check API keys")
