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

    model_config = {"env_file": ".env"}

@lru_cache()
def get_settings():
    return Settings()
