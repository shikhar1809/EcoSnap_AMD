from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List
import uuid
from datetime import datetime

router = APIRouter()

# Mock mock database for subsidies
applications_db = []

SUBSIDY_SCHEMES = [
    {
        "id": "ujala-ac",
        "name": "UJALA Energy Efficient AC",
        "description": "Get ₹8,000 subsidy on 5-star ACs.",
        "max_amount": 8000,
        "eligibility": "Income < ₹10L, Valid Electricity Bill"
    },
    {
        "id": "pm-surya-ghar",
        "name": "PM Surya Ghar Muft Bijli Yojana",
        "description": "Up to ₹78,000 for rooftop solar installation.",
        "max_amount": 78000,
        "eligibility": "Own roof space, Grid connected"
    },
    {
        "id": "se-fan-program",
        "name": "Super Efficient Fan Program",
        "description": "Subsidized BLDC fans at ₹1,500 off.",
        "max_amount": 1500,
        "eligibility": "Domestic connection"
    },
    {
        "id": "ewaste-incentive",
        "name": "State E-Waste Incentive",
        "description": "Get ₹500 per kg for certified e-waste recycling.",
        "max_amount": 5000,
        "eligibility": "Certified Recycler Receipt"
    },
    {
        "id": "furniture-reuse",
        "name": "Second-Hand Furniture Grant",
        "description": "Tax rebate for buying refurbished furniture.",
        "max_amount": 2000,
        "eligibility": "Purchase Invoice"
    }
]

class ApplicationCreate(BaseModel):
    user_id: str
    scheme_id: str
    appliance_details: str
    user_income_bracket: str

class Application(ApplicationCreate):
    id: str
    status: str # Submitted, Under Review, Approved, Rejected
    submitted_at: str
    updated_at: str

@router.get("/schemes")
async def get_schemes():
    return SUBSIDY_SCHEMES

@router.post("/apply", response_model=Application)
async def apply_subsidy(app: ApplicationCreate):
    # Verify scheme
    scheme = next((s for s in SUBSIDY_SCHEMES if s['id'] == app.scheme_id), None)
    if not scheme:
        raise HTTPException(status_code=404, detail="Scheme not found")
        
    new_app = Application(
        **app.dict(),
        id=str(uuid.uuid4()),
        status="Submitted",
        submitted_at=datetime.now().isoformat(),
        updated_at=datetime.now().isoformat()
    )
    applications_db.append(new_app)
    
    # Simulate auto-approval for demo
    if app.user_income_bracket != "High (>20L)":
        new_app.status = "Approved"
    
    return new_app

@router.get("/my-applications/{user_id}", response_model=List[Application])
async def get_user_applications(user_id: str):
    return [a for a in applications_db if a.user_id == user_id]
