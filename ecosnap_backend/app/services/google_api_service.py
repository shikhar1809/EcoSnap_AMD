"""
Google APIs Integration Service
Provides real-world data for enhanced analysis accuracy
"""
import requests
from typing import Optional, Dict, Any
from app.core.config import get_settings

settings = get_settings()

class GoogleAPIService:
    """Integration with Google Solar, Maps, and Weather APIs"""
    
    @staticmethod
    def get_solar_potential(lat: float, lon: float) -> Optional[Dict[str, Any]]:
        """
        Get real solar potential data from Google Solar API
        Returns satellite-verified roof analysis and financial projections
        """
        if not settings.GOOGLE_SOLAR_API_KEY:
            return None
            
        try:
            url = "https://solar.googleapis.com/v1/buildingInsights:findClosest"
            params = {
                "location.latitude": lat,
                "location.longitude": lon,
                "requiredQuality": "HIGH",
                "key": settings.GOOGLE_SOLAR_API_KEY
            }
            
            response = requests.get(url, params=params, timeout=10)
            if response.status_code == 200:
                data = response.json()
                solar_potential = data.get("solarPotential", {})
                
                return {
                    "roof_area_sqm": solar_potential.get("maxArrayAreaMeters2", 0),
                    "annual_sun_hours": solar_potential.get("maxSunshineHoursPerYear", 0),
                    "panel_configs": solar_potential.get("solarPanelConfigs", []),
                    "carbon_offset_kg_per_mwh": solar_potential.get("carbonOffsetFactorKgPerMwh", 0),
                    "financial_analyses": solar_potential.get("financialAnalyses", [])
                }
        except Exception as e:
            print(f"Google Solar API Error: {e}")
            return None
    
    @staticmethod
    def get_weather_data(lat: float, lon: float) -> Optional[Dict[str, Any]]:
        """
        Get current weather and climate data for location-aware analysis
        """
        if not settings.OPENWEATHER_API_KEY:
            return None
            
        try:
            # Current weather
            url = "https://api.openweathermap.org/data/2.5/weather"
            params = {
                "lat": lat,
                "lon": lon,
                "appid": settings.OPENWEATHER_API_KEY,
                "units": "metric"
            }
            
            response = requests.get(url, params=params, timeout=10)
            if response.status_code == 200:
                data = response.json()
                
                return {
                    "temperature": data["main"]["temp"],
                    "humidity": data["main"]["humidity"],
                    "weather": data["weather"][0]["main"],
                    "description": data["weather"][0]["description"],
                    "uv_index": data.get("uvi", 5),  # Default if not available
                    "city": data.get("name", "Unknown")
                }
        except Exception as e:
            print(f"Weather API Error: {e}")
            return None
    
    @staticmethod
    def get_location_context(lat: float, lon: float) -> Optional[Dict[str, Any]]:
        """
        Get location details for tariff lookup and local recommendations
        """
        if not settings.GOOGLE_MAPS_API_KEY:
            return None
            
        try:
            url = "https://maps.googleapis.com/maps/api/geocode/json"
            params = {
                "latlng": f"{lat},{lon}",
                "key": settings.GOOGLE_MAPS_API_KEY
            }
            
            response = requests.get(url, params=params, timeout=10)
            if response.status_code == 200:
                data = response.json()
                if data.get("results"):
                    result = data["results"][0]
                    components = result.get("address_components", [])
                    
                    city = None
                    state = None
                    
                    for component in components:
                        if "locality" in component["types"]:
                            city = component["long_name"]
                        if "administrative_area_level_1" in component["types"]:
                            state = component["long_name"]
                    
                    return {
                        "city": city,
                        "state": state,
                        "formatted_address": result.get("formatted_address"),
                        "lat": lat,
                        "lon": lon
                    }
        except Exception as e:
            print(f"Geocoding API Error: {e}")
            return None
    
    @staticmethod
    def get_enhanced_context(lat: float, lon: float) -> Dict[str, Any]:
        """
        Combine all API data for comprehensive context
        Falls back gracefully if APIs are not configured
        """
        context = {
            "location": {"lat": lat, "lon": lon},
            "has_solar_api": False,
            "has_weather_api": False,
            "has_maps_api": False
        }
        
        # Try to get solar data
        solar_data = GoogleAPIService.get_solar_potential(lat, lon)
        if solar_data:
            context["solar"] = solar_data
            context["has_solar_api"] = True
        
        # Try to get weather data
        weather_data = GoogleAPIService.get_weather_data(lat, lon)
        if weather_data:
            context["weather"] = weather_data
            context["has_weather_api"] = True
        
        # Try to get location context
        location_data = GoogleAPIService.get_location_context(lat, lon)
        if location_data:
            context["location"].update(location_data)
            context["has_maps_api"] = True
        
        return context
