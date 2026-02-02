from pydantic_settings import BaseSettings
from functools import lru_cache

class Settings(BaseSettings):
    PROJECT_NAME: str = "EcoSnap"
    VERSION: str = "0.1.0"
    API_V1_STR: str = "/api/v1"
    
    # Generate a secret key for JWT in production
    SECRET_KEY: str = "your-secret-key-here"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # Database
    # Supabase
    SUPABASE_URL: str
    SUPABASE_SERVICE_KEY: str
    
    # AI Keys
    GEMINI_API_KEY: str
    
    # Google APIs for Enhanced Analysis
    GOOGLE_SOLAR_API_KEY: str = ""  # Optional: Google Solar API
    GOOGLE_MAPS_API_KEY: str = ""   # Optional: Google Maps/Geocoding
    OPENWEATHER_API_KEY: str = ""   # Optional: Weather data

    model_config = {"env_file": ".env"}

@lru_cache()
def get_settings():
    return Settings()
