from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Optional, Dict
import uuid
from datetime import datetime

from app.services.subsidy_database import SubsidyDatabase, SchemeType

router = APIRouter()

# Mock database
applications_db = []

# ==================== MODELS ====================

class ApplicationCreate(BaseModel):
    user_id: str
    scheme_id: str
    appliance_details: Optional[str] = None
    user_income_bracket: Optional[str] = None

class Application(ApplicationCreate):
    id: str
    status: str  # Submitted, Under Review, Approved, Rejected
    submitted_at: str
    updated_at: str

class SubsidyRecommendationRequest(BaseModel):
    state: str
    action: str  # solar, ev, energy_efficiency, etc.
    capacity_kw: Optional[float] = None
    vehicle_type: Optional[str] = None
    income_bracket: Optional[str] = None

# ==================== COMPREHENSIVE SUBSIDY ENDPOINTS ====================

@router.get("/schemes/all")
async def get_all_schemes():
    """Get all central + state schemes"""
    return {
        "schemes": SubsidyDatabase.get_all_schemes(),
        "total_schemes": len(SubsidyDatabase.get_all_schemes()),
        "coverage": SubsidyDatabase.get_coverage_stats()
    }

@router.get("/schemes/central")
async def get_central_schemes():
    """Get all central government schemes"""
    return {
        "schemes": SubsidyDatabase.CENTRAL_SCHEMES,
        "total": len(SubsidyDatabase.CENTRAL_SCHEMES),
        "ministries": list(set(s['ministry'] for s in SubsidyDatabase.CENTRAL_SCHEMES))
    }

@router.get("/schemes/state/{state}")
async def get_state_schemes(state: str):
    """Get schemes for a specific state"""
    result = SubsidyDatabase.get_schemes_by_state(state)
    
    if state not in SubsidyDatabase.STATE_SCHEMES:
        raise HTTPException(status_code=404, detail=f"State '{state}' not found")
    
    return result

@router.get("/schemes/type/{scheme_type}")
async def get_schemes_by_type(scheme_type: SchemeType):
    """Get schemes by type (solar, EV, etc.)"""
    schemes = SubsidyDatabase.get_schemes_by_type(scheme_type)
    return {
        "type": scheme_type,
        "schemes": schemes,
        "total": len(schemes)
    }

@router.get("/trending/{state}")
async def get_trending_subsidies(state: str):
    """Get most used subsidies in the user's area"""
    return SubsidyDatabase.get_trending_schemes(state)

@router.post("/recommend")
async def recommend_subsidies(req: SubsidyRecommendationRequest):
    """
    Smart subsidy recommender
    Returns personalized subsidy recommendations based on user profile
    """
    user_profile = {
        "state": req.state,
        "action": req.action,
        "capacity_kw": req.capacity_kw,
        "vehicle_type": req.vehicle_type,
        "income_bracket": req.income_bracket
    }
    
    result = SubsidyDatabase.recommend_subsidies(user_profile)
    return result

@router.get("/coverage")
async def get_coverage_stats():
    """Get database coverage statistics"""
    return SubsidyDatabase.get_coverage_stats()

@router.get("/states")
async def get_all_states():
    """Get list of all states and UTs"""
    return {
        "states_uts": list(SubsidyDatabase.STATE_SCHEMES.keys()),
        "total": len(SubsidyDatabase.STATE_SCHEMES),
        "with_schemes": sum(1 for schemes in SubsidyDatabase.STATE_SCHEMES.values() if len(schemes) > 0)
    }

# ==================== APPLICATION MANAGEMENT ====================

@router.post("/apply", response_model=Application)
async def apply_subsidy(app: ApplicationCreate):
    """Apply for a subsidy scheme"""
    # Verify scheme exists
    all_schemes = SubsidyDatabase.get_all_schemes()
    scheme = next((s for s in all_schemes if s['id'] == app.scheme_id), None)
    
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
        new_app.status = "Under Review"
    
    return new_app

@router.get("/my-applications/{user_id}", response_model=List[Application])
async def get_user_applications(user_id: str):
    """Get all applications for a user"""
    user_apps = [a for a in applications_db if a.user_id == user_id]
    return user_apps

@router.get("/application/{application_id}")
async def get_application_status(application_id: str):
    """Track application status"""
    app = next((a for a in applications_db if a.id == application_id), None)
    
    if not app:
        raise HTTPException(status_code=404, detail="Application not found")
    
    # Simulate status progression
    timeline = [
        {"stage": "Submitted", "date": app.submitted_at, "status": "completed"},
        {"stage": "Document Verification", "date": app.updated_at, "status": "in_progress"},
        {"stage": "Technical Inspection", "date": None, "status": "pending"},
        {"stage": "Approval", "date": None, "status": "pending"},
        {"stage": "Disbursement", "date": None, "status": "pending"}
    ]
    
    return {
        "application": app,
        "timeline": timeline,
        "estimated_completion": "45-60 days from submission"
    }

# ==================== LEGACY ENDPOINTS (Backward Compatibility) ====================

@router.get("/schemes")
async def get_schemes():
    """Legacy endpoint - returns central schemes only"""
    return SubsidyDatabase.CENTRAL_SCHEMES

# ==================== DEMO DATA ====================

@router.get("/demo/solar-calculation")
async def demo_solar_subsidy_calculation(capacity_kw: float = 2.5, state: str = "Maharashtra"):
    """Demo: Calculate total solar subsidy"""
    result = SubsidyDatabase.recommend_subsidies({
        "state": state,
        "action": "solar",
        "capacity_kw": capacity_kw
    })
    
    return {
        "capacity_kw": capacity_kw,
        "state": state,
        **result,
        "example_calculation": {
            "system_cost": 125000,  # ₹50K per kW
            "total_subsidy": result['total_subsidy'],
            "net_cost": 125000 - result['total_subsidy'],
            "subsidy_percentage": round((result['total_subsidy'] / 125000) * 100, 1)
        }
    }

@router.get("/demo/ev-calculation")
async def demo_ev_subsidy_calculation(vehicle_type: str = "E-2W", state: str = "Delhi"):
    """Demo: Calculate total EV subsidy"""
    result = SubsidyDatabase.recommend_subsidies({
        "state": state,
        "action": "ev",
        "vehicle_type": vehicle_type
    })
    
    vehicle_costs = {
        "E-2W": 120000,
        "E-4W": 1500000
    }
    
    return {
        "vehicle_type": vehicle_type,
        "state": state,
        **result,
        "example_calculation": {
            "vehicle_cost": vehicle_costs.get(vehicle_type, 120000),
            "total_subsidy": result['total_subsidy'],
            "net_cost": vehicle_costs.get(vehicle_type, 120000) - result['total_subsidy'],
            "subsidy_percentage": round((result['total_subsidy'] / vehicle_costs.get(vehicle_type, 120000)) * 100, 1)
        }
    }
