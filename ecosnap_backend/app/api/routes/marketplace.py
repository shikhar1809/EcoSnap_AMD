from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Optional, Dict

from app.services.marketplace_service import MarketplaceService, ProductCategory

router = APIRouter()

# ==================== MODELS ====================

class ProductRecommendationRequest(BaseModel):
    action: str  # solar, energy_efficiency, sustainable
    budget: Optional[float] = 100000
    location: Optional[str] = "Mumbai"

# ==================== MARKETPLACE ENDPOINTS ====================

@router.get("/products")
async def get_products(category: Optional[ProductCategory] = None):
    """
    Get all products, optionally filtered by category
    Categories: solar_equipment, energy_efficient, sustainable_products, services
    """
    products = MarketplaceService.get_all_products(category=category.value if category else None)
    
    return {
        "products": products,
        "total": len(products),
        "category": category.value if category else "all"
    }

@router.get("/products/{product_id}")
async def get_product(product_id: str):
    """Get detailed product information"""
    product = MarketplaceService.get_product(product_id)
    
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    
    return product

@router.get("/products/search/{query}")
async def search_products(query: str, category: Optional[ProductCategory] = None):
    """Search products by name or subcategory"""
    results = MarketplaceService.search_products(
        query=query,
        category=category.value if category else None
    )
    
    return {
        "results": results,
        "total": len(results),
        "query": query
    }

@router.post("/products/recommend")
async def recommend_products(req: ProductRecommendationRequest):
    """
    Get smart product recommendations based on user profile
    AI-powered matching
    """
    recommendations = MarketplaceService.recommend_products({
        "action": req.action,
        "budget": req.budget,
        "location": req.location
    })
    
    return {
        "recommendations": recommendations,
        "total": len(recommendations),
        "criteria": {
            "action": req.action,
            "budget": req.budget,
            "location": req.location
        }
    }

@router.get("/products/{product_id}/roi")
async def calculate_product_roi(product_id: str, usage_hours_per_day: float = 8):
    """
    Calculate ROI for energy-efficient products
    Shows payback period, 5-year profit, ROI percentage
    """
    roi = MarketplaceService.calculate_roi(product_id, usage_hours_per_day)
    
    if "error" in roi:
        raise HTTPException(status_code=400, detail=roi["error"])
    
    return roi

@router.get("/sellers")
async def get_sellers(category: Optional[ProductCategory] = None):
    """
    Get all verified sellers
    Sorted by trust score
    """
    sellers = MarketplaceService.get_verified_sellers(
        category=category.value if category else None
    )
    
    return {
        "sellers": sellers,
        "total": len(sellers),
        "category": category.value if category else "all"
    }

@router.get("/sellers/{seller_id}")
async def get_seller(seller_id: str):
    """Get detailed seller information"""
    seller = MarketplaceService.get_seller(seller_id)
    
    if not seller:
        raise HTTPException(status_code=404, detail="Seller not found")
    
    # Get seller's products
    all_products = MarketplaceService.get_all_products()
    seller_products = [p for p in all_products if p['seller_id'] == seller_id]
    
    return {
        **seller,
        "products": seller_products,
        "total_products": len(seller_products)
    }

@router.get("/categories")
async def get_categories():
    """Get all product categories"""
    return {
        "categories": [
            {
                "id": "solar_equipment",
                "name": "Solar Equipment",
                "description": "Panels, Inverters, Batteries",
                "icon": "☀️"
            },
            {
                "id": "energy_efficient",
                "name": "Energy Efficient Appliances",
                "description": "5-Star ACs, BLDC Fans, LEDs",
                "icon": "⚡"
            },
            {
                "id": "sustainable_products",
                "name": "Sustainable Products",
                "description": "Reusable, Eco-Friendly Items",
                "icon": "🌱"
            },
            {
                "id": "services",
                "name": "Green Services",
                "description": "Installation, Recycling, Audits",
                "icon": "🛠️"
            }
        ]
    }

@router.get("/demo/solar-system")
async def demo_solar_system_pricing(capacity_kw: float = 2.5):
    """
    Demo: Complete solar system pricing with subsidy
    Shows total cost, subsidy, net cost, ROI
    """
    # Get solar products
    panels = MarketplaceService.get_product("sol_001")
    inverter = MarketplaceService.get_product("sol_003")
    installation = MarketplaceService.get_product("srv_001")
    
    # Calculate costs
    panels_needed = int(capacity_kw / 0.335)  # 335W per panel
    panel_cost = panels['price'] * panels_needed
    inverter_cost = inverter['price']
    installation_cost = 45000  # ₹45K for 2.5kW
    
    total_cost = panel_cost + inverter_cost + installation_cost
    
    # Subsidy (PM Surya Ghar)
    if capacity_kw <= 1:
        subsidy = 30000
    elif capacity_kw <= 2:
        subsidy = 60000
    else:
        subsidy = 78000
    
    net_cost = total_cost - subsidy
    
    # ROI calculation
    annual_savings = 18000  # ₹18K/year for 2.5kW
    payback_years = net_cost / annual_savings
    five_year_profit = (annual_savings * 5) - net_cost
    
    return {
        "system_capacity_kw": capacity_kw,
        "components": {
            "panels": {
                "product": panels['name'],
                "quantity": panels_needed,
                "cost": panel_cost
            },
            "inverter": {
                "product": inverter['name'],
                "quantity": 1,
                "cost": inverter_cost
            },
            "installation": {
                "service": installation['name'],
                "cost": installation_cost
            }
        },
        "pricing": {
            "total_cost": total_cost,
            "subsidy": subsidy,
            "net_cost": net_cost,
            "subsidy_percentage": round((subsidy / total_cost) * 100, 1)
        },
        "roi": {
            "annual_savings": annual_savings,
            "payback_period_years": round(payback_years, 1),
            "five_year_profit": five_year_profit,
            "roi_percentage": round((five_year_profit / net_cost) * 100, 1)
        },
        "sellers": [
            MarketplaceService.get_seller(panels['seller_id']),
            MarketplaceService.get_seller(inverter['seller_id'])
        ]
    }
