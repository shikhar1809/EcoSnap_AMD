"""Simple API diagnostic"""
import requests
import os
from dotenv import load_dotenv

load_dotenv()

# Get API keys
SOLAR_KEY = os.getenv('GOOGLE_SOLAR_API_KEY')
MAPS_KEY = os.getenv('GOOGLE_MAPS_API_KEY')
WEATHER_KEY = os.getenv('OPENWEATHER_API_KEY')

print("API Keys Loaded:")
print(f"Solar: {SOLAR_KEY[:20]}..." if SOLAR_KEY else "Solar: NOT FOUND")
print(f"Maps: {MAPS_KEY[:20]}..." if MAPS_KEY else "Maps: NOT FOUND")
print(f"Weather: {WEATHER_KEY[:20]}..." if WEATHER_KEY else "Weather: NOT FOUND")

# Test coordinates
lat, lon = 19.0760, 72.8777

print("\n" + "="*60)
print("TEST 1: OpenWeatherMap")
print("="*60)
try:
    url = f"https://api.openweathermap.org/data/2.5/weather"
    params = {"lat": lat, "lon": lon, "appid": WEATHER_KEY, "units": "metric"}
    r = requests.get(url, params=params, timeout=10)
    print(f"Status: {r.status_code}")
    if r.status_code == 200:
        data = r.json()
        print(f"SUCCESS: Temp={data['main']['temp']}C, City={data.get('name')}")
    else:
        print(f"ERROR: {r.text}")
except Exception as e:
    print(f"EXCEPTION: {e}")

print("\n" + "="*60)
print("TEST 2: Google Maps Geocoding")
print("="*60)
try:
    url = "https://maps.googleapis.com/maps/api/geocode/json"
    params = {"latlng": f"{lat},{lon}", "key": MAPS_KEY}
    r = requests.get(url, params=params, timeout=10)
    print(f"Status: {r.status_code}")
    if r.status_code == 200:
        data = r.json()
        if data.get('results'):
            print(f"SUCCESS: {data['results'][0].get('formatted_address')}")
        else:
            print(f"NO RESULTS: {data}")
    else:
        print(f"ERROR: {r.text}")
except Exception as e:
    print(f"EXCEPTION: {e}")

print("\n" + "="*60)
print("TEST 3: Google Solar API")
print("="*60)
try:
    url = "https://solar.googleapis.com/v1/buildingInsights:findClosest"
    params = {"location.latitude": lat, "location.longitude": lon, "key": SOLAR_KEY}
    r = requests.get(url, params=params, timeout=10)
    print(f"Status: {r.status_code}")
    if r.status_code == 200:
        data = r.json()
        print(f"SUCCESS: Found solar data")
    else:
        print(f"ERROR: {r.text[:200]}")
except Exception as e:
    print(f"EXCEPTION: {e}")
