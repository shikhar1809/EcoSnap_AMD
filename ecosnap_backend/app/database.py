from supabase import create_client, Client
from app.core.config import get_settings

settings = get_settings()

# Initialize Supabase Client
supabase: Client = create_client(settings.SUPABASE_URL, settings.SUPABASE_SERVICE_KEY)
