import os
import httpx
from dotenv import load_dotenv

load_dotenv()

class WeatherService:
    """
    Service to fetch REAL weather data and Google Solar insights.
    Uses:
    1. OpenWeatherMap (for Wind Speed/Direction) - Free Tier compatible
    2. Google Solar API (for Solar usage)
    """
    
    _solar_api_key = os.getenv("GOOGLE_SOLAR_API_KEY")
    _weather_api_key = os.getenv("OPENWEATHER_API_KEY")

    @staticmethod
    def get_wind_data(lat: float, lon: float):
        """
        Fetches current wind conditions from OpenWeatherMap.
        """
        if not WeatherService._weather_api_key:
            return {"error": "Missing OPENWEATHER_API_KEY"}

        try:
            url = f"https://api.openweathermap.org/data/2.5/weather?lat={lat}&lon={lon}&appid={WeatherService._weather_api_key}&units=metric"
            response = httpx.get(url, timeout=5.0)
            response.raise_for_status()
            data = response.json()
            
            wind = data.get("wind", {})
            speed = wind.get("speed", 0.0)
            
            # Determine suitability based on cut-in speed for small turbines (~3-4 m/s)
            suitability = "Low"
            if speed > 6.0: suitability = "High"
            elif speed > 3.5: suitability = "Moderate"
            
            return {
                "wind_speed_ms": speed,
                "wind_direction_deg": wind.get("deg", 0),
                "gust_speed_ms": wind.get("gust", speed),
                "suitability": suitability
            }
        except Exception as e:
            print(f"[WeatherService] Wind Error: {e}")
            return {"wind_speed_ms": 0, "suitability": "Error", "error": str(e)}

    @staticmethod
    def get_solar_potential(lat: float, lon: float):
        """
        Fetches solar potential from Google Solar API (Building Insights).
        """
        if not WeatherService._solar_api_key:
            return {"error": "Missing GOOGLE_SOLAR_API_KEY"}

        try:
            # buildingInsights:findClosest
            url = f"https://solar.googleapis.com/v1/buildingInsights:findClosest?location.latitude={lat}&location.longitude={lon}&requiredQuality=HIGH&key={WeatherService._solar_api_key}"
            
            response = httpx.get(url, timeout=10.0)
            if response.status_code == 404:
                return {"error": "No solar data for this precise location", "roof_suitability": "Unknown"}
            
            response.raise_for_status()
            data = response.json()
            
            solar_potential = data.get("solarPotential", {})
            max_panels = solar_potential.get("maxArrayPanelsCount", 0)
            max_sunshine = solar_potential.get("maxSunshineHoursPerYear", 0)
            
            return {
                "avg_sunlight_hours": round(max_sunshine / 365, 1),
                "roof_suitability": "Excellent" if max_panels > 10 else "Moderate",
                "max_panels": max_panels,
                "monthly_bill_estimates": solar_potential.get("financialAnalyses", [])
            }
        except Exception as e:
            print(f"[WeatherService] Solar Error: {e}")
            return {"avg_sunlight_hours": 0, "roof_suitability": "Error", "error": str(e)}
