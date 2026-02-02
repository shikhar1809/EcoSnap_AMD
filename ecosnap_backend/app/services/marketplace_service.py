from typing import Dict, List, Optional
from enum import Enum
from app.database import supabase
import json

class ProductCategory(str, Enum):
    SOLAR_EQUIPMENT = "solar_equipment"
    ENERGY_EFFICIENT = "energy_efficient"
    SUSTAINABLE_PRODUCTS = "sustainable_products"
    SERVICES = "services"

class MarketplaceService:
    """Verified eco-products marketplace supported by Supabase"""
    
    # SEED DATA (Only used if DB is empty)
    _SEED_PRODUCTS = {
        # Solar Equipment
        "solar_equipment": [
            {
                "id": "sol_001",
                "name": "Tata Solar Panel 335W Mono PERC",
                "category": "solar_equipment",
                "subcategory": "panels",
                "price": 12500,
                "specs": {"power": "335W", "efficiency": "20.5%"},
                "seller_id": "seller_001",
                "rating": 4.8,
                "in_stock": True
            },
            {
                "id": "sol_003",
                "name": "Luminous Solar Inverter 2kW",
                "category": "solar_equipment",
                "subcategory": "inverters",
                "price": 25000,
                "specs": {"capacity": "2kW", "mppt": True},
                "seller_id": "seller_002",
                "rating": 4.7,
                "in_stock": True
            }
        ],
        "energy_efficient": [
             {
                "id": "ee_001",
                "name": "LG 5-Star Inverter AC 1.5 Ton",
                "category": "energy_efficient",
                "subcategory": "air_conditioners",
                "price": 34999,
                "specs": {"star_rating": 5, "iseer": "5.2"},
                "seller_id": "seller_003",
                "rating": 4.6,
                "in_stock": True,
                "savings_per_year": 6000
            }
        ],
        "sustainable_products": [
             {
                "id": "sus_001",
                "name": "Milton Thermosteel Bottle 1L",
                "category": "sustainable_products",
                "subcategory": "reusable_bottles",
                "price": 450,
                "specs": {"material": "Stainless Steel"},
                "seller_id": "seller_004",
                "rating": 4.7,
                "in_stock": True
            }
        ],
        "services": [
             {
                "id": "srv_001",
                "name": "MNRE Certified Solar Installation",
                "category": "services",
                "subcategory": "solar_installation",
                "price": 45000,
                "specs": {"certification": "MNRE Approved"},
                "seller_id": "seller_001",
                "rating": 4.9,
                "in_stock": True
            }
        ]
    }

    _SEED_SELLERS = {
        "seller_001": {"id": "seller_001", "name": "SunPower India", "trust_score": 95, "verified": True},
        "seller_002": {"id": "seller_002", "name": "GreenTech Solutions", "trust_score": 92, "verified": True},
        "seller_003": {"id": "seller_003", "name": "EcoMart India", "trust_score": 94, "verified": True},
        "seller_004": {"id": "seller_004", "name": "Sustainable Living Co", "trust_score": 93, "verified": True},
    }

    @classmethod
    def _ensure_initialized(cls):
        """Seed products if table is empty"""
        try:
            res = supabase.table("products").select("count", count="exact").execute()
            if res.count == 0:
                print("Seeding Marketplace DB...")
                cls._seed_db()
        except Exception as e:
            print(f"Marketplace Init Error: {e}")

    @classmethod
    def _seed_db(cls):
        # Seed Sellers
        sellers = list(cls._SEED_SELLERS.values())
        try:
            supabase.table("sellers").upsert(sellers).execute()
        except: pass

        # Seed Products
        all_products = []
        for cat_prods in cls._SEED_PRODUCTS.values():
            all_products.extend(cat_prods)
        
        try:
            supabase.table("products").upsert(all_products).execute()
        except Exception as e:
            print(f"Seeding Products Error: {e}")

    @classmethod
    def get_all_products(cls, category: Optional[str] = None) -> List[Dict]:
        """Fetch products from Real DB"""
        cls._ensure_initialized()
        try:
            query = supabase.table("products").select("*, sellers(*)") # Join sellers
            if category:
                query = query.eq("category", category)
            
            res = query.execute()
            # If relation join fails, just return products
            if not res.data:
                 print("Fetch empty, ensuring seed...")
                 cls._seed_db()
                 return supabase.table("products").select("*").execute().data

            return res.data
        except Exception as e:
            print(f"Fetch Products Error: {e}")
            return []

    @classmethod
    def get_product(cls, product_id: str) -> Optional[Dict]:
        try:
            res = supabase.table("products").select("*, sellers(*)").eq("id", product_id).execute()
            if res.data:
                return res.data[0]
            return None
        except: return None

    @classmethod
    def search_products(cls, query: str, category: Optional[str] = None) -> List[Dict]:
        """Real DB Search"""
        cls._ensure_initialized()
        try:
            # Using ilike for search
            db_query = supabase.table("products").select("*").ilike("name", f"%{query}%")
            if category:
                db_query = db_query.eq("category", category)
            return db_query.execute().data
        except: return []

    @classmethod
    def recommend_products(cls, user_profile: Dict) -> List[Dict]:
        """Recommendation Logic hitting DB"""
        cls._ensure_initialized()
        action = user_profile.get("action", "solar")
        budget = user_profile.get("budget", 100000)
        
        category = "solar_equipment"
        if action == "energy_efficiency": category = "energy_efficient"
        elif action == "sustainable": category = "sustainable_products"

        try:
            # Fetch products in category below budget
            res = supabase.table("products").select("*")\
                .eq("category", category)\
                .lte("price", budget)\
                .order("rating", desc=True)\
                .limit(5)\
                .execute()
            return res.data
        except: return []

    @classmethod
    def calculate_roi(cls, product_id: str, usage_hours_per_day: float = 8) -> Dict:
        product = cls.get_product(product_id)
        if not product or not product.get('savings_per_year'):
            return {"error": "ROI data unavailable"}

        price = product.get('price', 0)
        savings = product.get('savings_per_year', 0)
        
        return {
            "product": product['name'],
            "upfront_cost": price,
            "annual_savings": savings,
            "payback_period_months": round((price / savings) * 12, 1),
            "five_year_profit": (savings * 5) - price,
            "roi_percentage": round(((savings * 5 - price) / price) * 100, 1)
        }

    # ... get_seller, etc. mapped similarly ...
    @classmethod
    def get_seller(cls, seller_id: str) -> Optional[Dict]:
        try:
            res = supabase.table("sellers").select("*").eq("id", seller_id).execute()
            return res.data[0] if res.data else None
        except: return None

    @classmethod
    def get_verified_sellers(cls, category: Optional[str] = None) -> List[Dict]:
        try:
             # Ideally we join products to filter sellers by category, but keep simple
             return supabase.table("sellers").select("*").eq("verified", True).execute().data
        except: return []
