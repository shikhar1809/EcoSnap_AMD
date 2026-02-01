from fastapi import APIRouter, HTTPException, UploadFile, File
from pydantic import BaseModel
from typing import List, Optional, Dict
import uuid
from datetime import datetime

from app.services.ai_service import AIService
from app.services.carbon_credit_service import (
    CCTSEngine, OffsetProjectEngine, PersonalCarbonWallet, Sector
)

router = APIRouter()

# Mock DB (replace with actual database in production)
user_credits_db = {}  # user_id -> balance
transactions_db = []
carbon_wallets_db = {}  # user_id -> wallet data
offset_projects_db = []

# ==================== MODELS ====================

class Transaction(BaseModel):
    id: str
    user_id: str
    type: str  # EARN, BUY, SELL
    amount: float
    price_per_credit: float = 0
    date: str

class TradeRequest(BaseModel):
    user_id: str
    amount: float
    action: str  # BUY or SELL

class CCTSComplianceRequest(BaseModel):
    sector: Sector
    emissions_tco2: float
    production_tonnes: float
    company_name: Optional[str] = None

class OffsetProjectRequest(BaseModel):
    user_id: str
    project_type: str
    project_data: Dict
    project_name: Optional[str] = None

class HouseholdEmissionsRequest(BaseModel):
    user_id: str
    monthly_consumption: Dict

# ==================== CCTS 2023 ENDPOINTS ====================

@router.post("/ccts/calculate")
async def calculate_ccts_compliance(req: CCTSComplianceRequest):
    """
    Calculate CCTS 2023 compliance for obligated entities
    Returns CCC surplus or deficit
    """
    result = CCTSEngine.calculate_ccc_eligibility(
        sector=req.sector,
        emissions_tco2=req.emissions_tco2,
        production_tonnes=req.production_tonnes
    )
    
    if req.company_name:
        result['company_name'] = req.company_name
    
    return result

@router.get("/ccts/sectors")
async def get_ccts_sectors():
    """Get all 9 CCTS 2023 obligated sectors with targets"""
    return {
        "sectors": [
            {
                "name": sector.value,
                "target_intensity": CCTSEngine.SECTOR_TARGETS[sector],
                "unit": "tCO2e per tonne product",
                "effective_from": "April 2025"
            }
            for sector in Sector
        ],
        "total_sectors": len(Sector),
        "administered_by": "Bureau of Energy Efficiency (BEE)",
        "trading_via": "CERC-approved power exchanges"
    }

@router.get("/ccts/market/price")
async def get_ccc_market_price():
    """Get current CCC market price from ICM"""
    return CCTSEngine.get_current_ccc_price()

# ==================== OFFSET PROJECTS ====================

@router.post("/offset/calculate")
async def calculate_offset_credits(req: OffsetProjectRequest):
    """
    Calculate offset credits for voluntary projects
    (Renewable energy, reforestation, waste management, etc.)
    """
    result = OffsetProjectEngine.calculate_offset_credits(
        project_type=req.project_type,
        project_data=req.project_data
    )
    
    # Store project
    project = {
        "id": str(uuid.uuid4()),
        "user_id": req.user_id,
        "project_name": req.project_name or result.get("project_name"),
        **result,
        "status": "Pending Verification",
        "submitted_at": datetime.now().isoformat()
    }
    offset_projects_db.append(project)
    
    return project

@router.get("/offset/projects/{user_id}")
async def get_user_offset_projects(user_id: str):
    """Get all offset projects for a user"""
    projects = [p for p in offset_projects_db if p['user_id'] == user_id]
    return {
        "projects": projects,
        "total_credits_pending": sum(p.get('credits_earned', 0) for p in projects),
        "total_value_pending": sum(p.get('estimated_value', 0) for p in projects)
    }

@router.get("/offset/types")
async def get_offset_project_types():
    """Get all available offset project types"""
    return {
        "project_types": OffsetProjectEngine.PROJECT_TYPES,
        "note": "All projects require BEE verification before CCC issuance"
    }

# ==================== PERSONAL CARBON WALLET ====================

@router.post("/wallet/calculate")
async def calculate_household_emissions(req: HouseholdEmissionsRequest):
    """
    Calculate household carbon footprint and recommendations
    """
    result = PersonalCarbonWallet.calculate_household_emissions(req.monthly_consumption)
    
    # Store in wallet
    carbon_wallets_db[req.user_id] = {
        "user_id": req.user_id,
        "last_updated": datetime.now().isoformat(),
        **result
    }
    
    return result

@router.get("/wallet/{user_id}")
async def get_carbon_wallet(user_id: str):
    """Get user's carbon wallet"""
    wallet = carbon_wallets_db.get(user_id)
    if not wallet:
        return {
            "user_id": user_id,
            "message": "No data yet. Calculate your emissions to get started!",
            "ccc_balance": user_credits_db.get(user_id, 0.0)
        }
    
    wallet['ccc_balance'] = user_credits_db.get(user_id, 0.0)
    return wallet

@router.get("/wallet/{user_id}/transactions")
async def get_wallet_transactions(user_id: str):
    """Get transaction history"""
    user_transactions = [t for t in transactions_db if t.user_id == user_id]
    return {
        "transactions": user_transactions,
        "total_earned": sum(t.amount for t in user_transactions if t.type == "EARN"),
        "total_bought": sum(t.amount for t in user_transactions if t.type == "BUY"),
        "total_sold": sum(t.amount for t in user_transactions if t.type == "SELL"),
    }

# ==================== LEGACY ENDPOINTS (Updated) ====================

@router.get("/balance/{user_id}")
async def get_balance(user_id: str):
    """Get CCC balance"""
    return {
        "balance": user_credits_db.get(user_id, 0.0),
        "unit": "tCO2e",
        "current_market_value": user_credits_db.get(user_id, 0.0) * CCTSEngine.CCC_BASE_PRICE
    }

@router.post("/earn")
async def earn_credits(user_id: str, co2_saved_kg: float, source: str = "green_action"):
    """
    Earn carbon credits for green actions
    1 CCC = 1 tCO2e saved
    """
    credits_earned = co2_saved_kg / 1000.0  # Convert kg to tonnes
    
    current = user_credits_db.get(user_id, 0.0)
    user_credits_db[user_id] = current + credits_earned
    
    # Log transaction
    transaction = Transaction(
        id=str(uuid.uuid4()),
        user_id=user_id,
        type="EARN",
        amount=credits_earned,
        date=datetime.now().isoformat()
    )
    transactions_db.append(transaction)
    
    return {
        "message": "Credits earned",
        "earned": round(credits_earned, 4),
        "source": source,
        "new_balance": user_credits_db[user_id],
        "market_value": round(credits_earned * CCTSEngine.CCC_BASE_PRICE, 2)
    }

@router.post("/trade")
async def trade_credits(req: TradeRequest):
    """Trade CCCs on ICM (Indian Carbon Market)"""
    current = user_credits_db.get(req.user_id, 0.0)
    market_data = CCTSEngine.get_current_ccc_price()
    market_price = market_data['price_per_tco2']
    
    if req.action == "SELL":
        if current < req.amount:
            raise HTTPException(status_code=400, detail="Insufficient credits")
        user_credits_db[req.user_id] = current - req.amount
        total_value = req.amount * market_price
        msg = f"Sold {req.amount} CCCs for ₹{total_value:,.2f}"
        
    elif req.action == "BUY":
        user_credits_db[req.user_id] = current + req.amount
        total_cost = req.amount * market_price
        msg = f"Bought {req.amount} CCCs for ₹{total_cost:,.2f}"
        
    else:
        raise HTTPException(status_code=400, detail="Invalid action")
        
    transaction = Transaction(
        id=str(uuid.uuid4()),
        user_id=req.user_id,
        type=req.action,
        amount=req.amount,
        price_per_credit=market_price,
        date=datetime.now().isoformat()
    )
    transactions_db.append(transaction)
    
    return {
        "message": msg,
        "new_balance": user_credits_db[req.user_id],
        "market_price": market_price,
        "exchange": market_data['exchange']
    }

@router.get("/history/{user_id}")
async def get_history(user_id: str):
    """Get transaction history"""
    return [t for t in transactions_db if t.user_id == user_id]

# ==================== BILL ANALYSIS ====================

@router.post("/analyze_bill")
async def analyze_bill_endpoint(file: UploadFile = File(...)):
    """
    Upload an electricity bill image to get extracted data
    Used for ROI calculations in Bill Analysis screen
    """
    contents = await file.read()
    data = AIService.analyze_bill(contents)
    return data

# ==================== DEMO DATA ====================

@router.get("/demo/compliance")
async def get_demo_compliance_data():
    """Get demo compliance data for testing"""
    from app.services.carbon_credit_service import DEMO_COMPLIANCE_DATA
    
    results = {}
    for company_id, data in DEMO_COMPLIANCE_DATA.items():
        results[company_id] = CCTSEngine.calculate_ccc_eligibility(
            sector=data['sector'],
            emissions_tco2=data['emissions_tco2'],
            production_tonnes=data['production_tonnes']
        )
        results[company_id]['company'] = data['company']
    
    return results

@router.get("/demo/offset-projects")
async def get_demo_offset_projects():
    """Get demo offset projects"""
    from app.services.carbon_credit_service import DEMO_OFFSET_PROJECTS
    
    results = {}
    for project_id, data in DEMO_OFFSET_PROJECTS.items():
        results[project_id] = OffsetProjectEngine.calculate_offset_credits(
            project_type=data['type'],
            project_data=data['data']
        )
        results[project_id]['owner'] = data['owner']
    
    return results
