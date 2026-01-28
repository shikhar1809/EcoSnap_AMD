from fastapi import APIRouter
from pydantic import BaseModel
import random

router = APIRouter()

class AnalysisRequest(BaseModel):
    appliance_type: str # e.g., "AC", "Fridge"
    age_years: float
    usage_hours_daily: float
    brand: str
    last_serviced_months_ago: int

class MaintenanceAnalysis(BaseModel):
    appliance_type: str
    health_score: int # 0-100
    failure_probability: float # 0.0 - 1.0
    predicted_failure_days: int
    recommendation: str
    status: str # Good, Warning, Critical

@router.post("/analyze", response_model=MaintenanceAnalysis)
async def analyze_appliance(data: AnalysisRequest):
    """
    Simulates XGBoost predictive maintenance model.
    """
    # Heuristic Logic for MVP
    base_score = 100
    
    # Age factor
    base_score -= (data.age_years * 5)
    
    # Usage factor
    if data.usage_hours_daily > 8:
        base_score -= 10
        
    # Service factor
    if data.last_serviced_months_ago > 6:
        base_score -= 15
    if data.last_serviced_months_ago > 12:
        base_score -= 20
        
    # Brand reliability (dummy)
    if data.brand.lower() in ["unknown", "generic"]:
        base_score -= 10
        
    # Random noise for realism
    base_score += random.randint(-5, 5)
    
    # Clamp score
    health_score = max(0, min(100, int(base_score)))
    
    # Derive predictions
    failure_prob = round((100 - health_score) / 100.0, 2)
    predicted_days = int(health_score * 5) + random.randint(10, 60)
    
    status = "Good"
    recommendation = "No action needed."
    
    if health_score < 50:
        status = "Critical"
        recommendation = "Immediate service required! High risk of compressor failure."
    elif health_score < 75:
        status = "Warning"
        recommendation = "Schedule maintenance within 2 weeks to prevent efficiency loss."
        
    return MaintenanceAnalysis(
        appliance_type=data.appliance_type,
        health_score=health_score,
        failure_probability=failure_prob,
        predicted_failure_days=predicted_days,
        recommendation=recommendation,
        status=status
    )
