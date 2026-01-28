from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List
import uuid
from datetime import datetime

router = APIRouter()

# Mock DB
user_credits_db = {} # user_id -> balance
transactions_db = []

class Transaction(BaseModel):
    id: str
    user_id: str
    type: str # EARN, BUY, SELL
    amount: float
    price_per_credit: float = 0
    date: str

class TradeRequest(BaseModel):
    user_id: str
    amount: float
    action: str # BUY or SELL

@router.get("/balance/{user_id}")
async def get_balance(user_id: str):
    return {"balance": user_credits_db.get(user_id, 0.0)}

@router.post("/earn")
async def earn_credits(user_id: str, co2_saved_kg: float):
    # 1 credit = 100kg CO2
    credits_earned = co2_saved_kg / 100.0
    
    current = user_credits_db.get(user_id, 0.0)
    user_credits_db[user_id] = current + credits_earned
    
    # Log transaction
    transactions_db.append(Transaction(
        id=str(uuid.uuid4()),
        user_id=user_id,
        type="EARN",
        amount=credits_earned,
        date=datetime.now().isoformat()
    ))
    
    return {"message": "Credits earned", "earned": credits_earned, "new_balance": user_credits_db[user_id]}

@router.post("/trade")
async def trade_credits(req: TradeRequest):
    current = user_credits_db.get(req.user_id, 0.0)
    market_price = 75.0 # Fixed price for MVP
    
    if req.action == "SELL":
        if current < req.amount:
            raise HTTPException(status_code=400, detail="Insufficient credits")
        user_credits_db[req.user_id] = current - req.amount
        total_value = req.amount * market_price
        msg = f"Sold {req.amount} credits for ₹{total_value}"
        
    elif req.action == "BUY":
        # Assume payment success
        user_credits_db[req.user_id] = current + req.amount
        total_cost = req.amount * market_price
        msg = f"Bought {req.amount} credits for ₹{total_cost}"
        
    else:
        raise HTTPException(status_code=400, detail="Invalid action")
        
    transactions_db.append(Transaction(
        id=str(uuid.uuid4()),
        user_id=req.user_id,
        type=req.action,
        amount=req.amount,
        price_per_credit=market_price,
        date=datetime.now().isoformat()
    ))
    
    return {"message": msg, "new_balance": user_credits_db[req.user_id]}

@router.get("/history/{user_id}")
async def get_history(user_id: str):
    return [t for t in transactions_db if t.user_id == user_id]
