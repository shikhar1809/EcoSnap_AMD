from app.database import supabase
import json

try:
    # Try to select from 'questions' to see if it exists
    res = supabase.table("questions").select("*").limit(1).execute()
    print("Questions table exists.")
except Exception as e:
    print(f"Questions table error: {e}")

try:
    # Try to select from 'marketplace' to see if it exists
    res = supabase.table("marketplace").select("*").limit(1).execute()
    print("Marketplace table exists.")
except Exception as e:
    print(f"Marketplace table error: {e}")

try:
    # Try to select from 'redemptions' to see if it exists
    res = supabase.table("redemptions").select("*").limit(1).execute()
    print("Redemptions table exists.")
except Exception as e:
    print(f"Redemptions table error: {e}")

try:
    # Try to select 'carbon_saved' from 'users'
    res = supabase.table("users").select("carbon_saved").limit(1).execute()
    print("Carbon saved column exists.")
except Exception as e:
    print(f"Carbon saved column error: {e}")
