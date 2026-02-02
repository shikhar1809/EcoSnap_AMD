"""Test geospatial APIs"""
import sys
sys.path.append('.')

from app.services.geospatial_service import GeospatialService

# Test coordinates (Mumbai)
lat, lon = 19.0760, 72.8777

print("="*70)
print("TESTING OPEN-SOURCE GEOSPATIAL DATA SOURCES")
print("="*70)

print(f"\nTest Location: {lat}, {lon} (Mumbai, India)")

# Test 1: Elevation
print("\n1. Open-Elevation API (Terrain Data)")
elevation = GeospatialService.get_elevation(lat, lon)
if elevation:
    print(f"   [SUCCESS] Elevation: {elevation}m above sea level")
else:
    print("   [FAILED]")

# Test 2: NASA Solar
print("\n2. NASA POWER API (Solar Irradiance)")
nasa = GeospatialService.get_nasa_solar_data(lat, lon)
if nasa:
    print(f"   [SUCCESS] Daily Irradiance: {nasa['avg_daily_irradiance_kwh_m2']} kWh/m2")
    print(f"   Annual Irradiance: {nasa['annual_irradiance_kwh_m2']} kWh/m2")
else:
    print("   [FAILED]")

# Test 3: OpenStreetMap
print("\n3. OpenStreetMap (Building Data)")
osm = GeospatialService.get_osm_building_data(lat, lon, radius=100)
if osm:
    print(f"   [SUCCESS] Buildings found: {osm['buildings_found']}")
    if osm['nearest_building']:
        print(f"   Nearest building: {osm['nearest_building']}")
else:
    print("   [FAILED]")

# Test 4: Air Quality
print("\n4. OpenAQ (Air Quality)")
air = GeospatialService.get_air_quality(lat, lon)
if air:
    print(f"   [SUCCESS] PM2.5: {air.get('pm25', 'N/A')}")
else:
    print("   [FAILED or No nearby stations]")

# Test 5: Sun Position
print("\n5. Astronomical Calculations (Sun Position)")
sun = GeospatialService.calculate_sun_position(lat, lon)
print(f"   [SUCCESS] Optimal tilt: {sun['optimal_tilt_year_round']}°")
print(f"   Optimal azimuth: {sun['optimal_azimuth']}°")
print(f"   Hemisphere: {sun['hemisphere']}")

# Test 6: Climate Zone
print("\n6. Climate Zone Classification")
climate = GeospatialService.get_climate_zone(lat, lon)
print(f"   [SUCCESS] Climate Zone: {climate}")

# Test 7: Combined Context
print("\n7. Enhanced Geospatial Context (All Combined)")
context = GeospatialService.get_enhanced_geospatial_context(lat, lon)
print(f"   Data sources active: {len(context['data_sources'])}")
print(f"   Sources: {', '.join(context['data_sources'])}")

print("\n" + "="*70)
print("TEST COMPLETE")
print("="*70)
