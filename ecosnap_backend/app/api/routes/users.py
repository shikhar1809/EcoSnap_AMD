from fastapi import APIRouter, HTTPException
from typing import List

from app.database import supabase
from app.schemas.user import UserCreate, User
from passlib.context import CryptContext
import uuid

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

router = APIRouter()

def get_password_hash(password):
    return pwd_context.hash(password)

@router.post("/", response_model=User)
def create_user(user_in: UserCreate):
    """
    Create new user in Supabase.
    """
    # Check if user exists
    existing_user = supabase.table("users").select("*").eq("email", user_in.email).execute()
    
    if existing_user.data:
        raise HTTPException(
            status_code=400,
            detail="The user with this username already exists in the system.",
        )
    
    # Prepare user data
    user_id = str(uuid.uuid4())
    user_data = {
        "id": user_id,
        "email": user_in.email,
        "hashed_password": get_password_hash(user_in.password),
        "full_name": user_in.full_name,
        "city": user_in.city,
        "is_active": True,
        "is_superuser": False,
        "subscription_tier": "free"
    }

    # Insert into Supabase
    try:
        response = supabase.table("users").insert(user_data).execute()
        # Return the created user (converting response data to schema)
        if response.data:
            return response.data[0]
        else:
             raise HTTPException(status_code=500, detail="Failed to create user in Supabase")
    except Exception as e:
        print(f"Supabase Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/", response_model=List[User])
def read_users(skip: int = 0, limit: int = 100):
    """
    Retrieve users from Supabase.
    """
    try:
        # Supabase range is 0-indexed, inclusive
        response = supabase.table("users").select("*").range(skip, skip + limit - 1).execute()
        return response.data
    except Exception as e:
         print(f"Supabase Error: {e}")
         raise HTTPException(status_code=500, detail=str(e))
