"""
Verified Marketplace Service
Product catalog, seller verification, smart recommendations
"""
from typing import Dict, List, Optional
from enum import Enum

class ProductCategory(str, Enum):
    SOLAR_EQUIPMENT = "solar_equipment"
    ENERGY_EFFICIENT = "energy_efficient"
    SUSTAINABLE_PRODUCTS = "sustainable_products"
    SERVICES = "services"

class MarketplaceService:
    """Verified eco-products marketplace"""
    
    # Product catalog
    PRODUCTS = {
        # Solar Equipment
        "solar_equipment": [
            {
                "id": "sol_001",
                "name": "Tata Solar Panel 335W Mono PERC",
                "category": "solar_equipment",
                "subcategory": "panels",
                "price": 12500,
                "specs": {
                    "power": "335W",
                    "efficiency": "20.5%",
                    "warranty": "25 years performance",
                    "dimensions": "1956x992x40mm"
                },
                "certifications": ["IEC 61215", "IEC 61730", "BIS"],
                "seller_id": "seller_001",
                "rating": 4.8,
                "reviews_count": 342,
                "in_stock": True,
                "subsidy_eligible": True
            },
            {
                "id": "sol_002",
                "name": "Adani Solar Panel 440W Bifacial",
                "category": "solar_equipment",
                "subcategory": "panels",
                "price": 15000,
                "specs": {
                    "power": "440W",
                    "efficiency": "21.2%",
                    "warranty": "25 years performance",
                    "bifacial": True
                },
                "certifications": ["IEC 61215", "IEC 61730", "BIS"],
                "seller_id": "seller_001",
                "rating": 4.9,
                "reviews_count": 567,
                "in_stock": True,
                "subsidy_eligible": True
            },
            {
                "id": "sol_003",
                "name": "Luminous Solar Inverter 2kW",
                "category": "solar_equipment",
                "subcategory": "inverters",
                "price": 25000,
                "specs": {
                    "capacity": "2kW",
                    "efficiency": "97.5%",
                    "mppt": True,
                    "warranty": "5 years"
                },
                "certifications": ["BIS", "ISO 9001"],
                "seller_id": "seller_002",
                "rating": 4.7,
                "reviews_count": 234,
                "in_stock": True,
                "subsidy_eligible": False
            }
        ],
        
        # Energy Efficient Appliances
        "energy_efficient": [
            {
                "id": "ee_001",
                "name": "LG 5-Star Inverter AC 1.5 Ton",
                "category": "energy_efficient",
                "subcategory": "air_conditioners",
                "price": 34999,
                "specs": {
                    "capacity": "1.5 Ton",
                    "star_rating": 5,
                    "iseer": "5.2",
                    "annual_power": "750 kWh/year"
                },
                "certifications": ["BEE 5-Star", "ISO 14001"],
                "seller_id": "seller_003",
                "rating": 4.6,
                "reviews_count": 1234,
                "in_stock": True,
                "subsidy_eligible": True,
                "savings_per_year": 6000
            },
            {
                "id": "ee_002",
                "name": "Atomberg BLDC Ceiling Fan",
                "category": "energy_efficient",
                "subcategory": "fans",
                "price": 2499,
                "specs": {
                    "power": "28W",
                    "savings": "65% vs regular fan",
                    "warranty": "2 years"
                },
                "certifications": ["BEE", "Energy Star"],
                "seller_id": "seller_003",
                "rating": 4.8,
                "reviews_count": 5678,
                "in_stock": True,
                "subsidy_eligible": True,
                "savings_per_year": 800
            }
        ],
        
        # Sustainable Products
        "sustainable_products": [
            {
                "id": "sus_001",
                "name": "Milton Thermosteel Bottle 1L",
                "category": "sustainable_products",
                "subcategory": "reusable_bottles",
                "price": 450,
                "specs": {
                    "capacity": "1L",
                    "material": "Stainless Steel",
                    "insulation": "24 hours hot/cold"
                },
                "certifications": ["BPA-Free", "Food Grade"],
                "seller_id": "seller_004",
                "rating": 4.7,
                "reviews_count": 8901,
                "in_stock": True,
                "subsidy_eligible": False,
                "environmental_impact": "Saves 500 plastic bottles/year"
            },
            {
                "id": "sus_002",
                "name": "Bamboo Toothbrush Pack of 4",
                "category": "sustainable_products",
                "subcategory": "personal_care",
                "price": 199,
                "specs": {
                    "material": "100% Bamboo",
                    "biodegradable": True,
                    "pack_size": 4
                },
                "certifications": ["Eco-Certified", "Vegan"],
                "seller_id": "seller_004",
                "rating": 4.5,
                "reviews_count": 456,
                "in_stock": True,
                "subsidy_eligible": False,
                "environmental_impact": "Reduces plastic waste by 80g/year"
            }
        ],
        
        # Services
        "services": [
            {
                "id": "srv_001",
                "name": "MNRE Certified Solar Installation",
                "category": "services",
                "subcategory": "solar_installation",
                "price_range": "₹40,000 - ₹50,000 per kW",
                "specs": {
                    "certification": "MNRE Approved",
                    "warranty": "5 years installation",
                    "includes": "Design, Installation, Net Metering"
                },
                "certifications": ["MNRE", "ISO 9001", "BIS"],
                "seller_id": "seller_001",
                "rating": 4.9,
                "reviews_count": 234,
                "in_stock": True,
                "subsidy_eligible": True
            },
            {
                "id": "srv_002",
                "name": "E-Waste Recycling Service",
                "category": "services",
                "subcategory": "recycling",
                "price_range": "Free pickup + ₹500/kg payment",
                "specs": {
                    "authorized": "CPCB Authorized",
                    "pickup": "Free doorstep pickup",
                    "payment": "Cash on collection"
                },
                "certifications": ["CPCB", "ISO 14001"],
                "seller_id": "seller_005",
                "rating": 4.6,
                "reviews_count": 567,
                "in_stock": True,
                "subsidy_eligible": False
            }
        ]
    }
    
    # Seller database
    SELLERS = {
        "seller_001": {
            "id": "seller_001",
            "name": "SunPower India Pvt Ltd",
            "category": "solar_equipment",
            "verified": True,
            "certifications": ["MNRE Approved", "ISO 9001", "BIS"],
            "rating": 4.8,
            "total_reviews": 1143,
            "years_in_business": 8,
            "completed_projects": 2500,
            "trust_score": 95,
            "location": "Mumbai, Maharashtra",
            "response_time": "< 2 hours"
        },
        "seller_002": {
            "id": "seller_002",
            "name": "GreenTech Solutions",
            "category": "solar_equipment",
            "verified": True,
            "certifications": ["ISO 9001", "BIS"],
            "rating": 4.7,
            "total_reviews": 567,
            "years_in_business": 5,
            "completed_projects": 1200,
            "trust_score": 92,
            "location": "Bangalore, Karnataka",
            "response_time": "< 4 hours"
        },
        "seller_003": {
            "id": "seller_003",
            "name": "EcoMart India",
            "category": "energy_efficient",
            "verified": True,
            "certifications": ["BEE Authorized", "ISO 14001"],
            "rating": 4.6,
            "total_reviews": 6912,
            "years_in_business": 12,
            "completed_projects": 15000,
            "trust_score": 94,
            "location": "Delhi, NCR",
            "response_time": "< 1 hour"
        },
        "seller_004": {
            "id": "seller_004",
            "name": "Sustainable Living Co",
            "category": "sustainable_products",
            "verified": True,
            "certifications": ["Eco-Certified", "Fair Trade"],
            "rating": 4.7,
            "total_reviews": 9357,
            "years_in_business": 6,
            "completed_projects": 25000,
            "trust_score": 93,
            "location": "Pune, Maharashtra",
            "response_time": "< 3 hours"
        },
        "seller_005": {
            "id": "seller_005",
            "name": "E-Parisaraa Recycling",
            "category": "services",
            "verified": True,
            "certifications": ["CPCB Authorized", "ISO 14001"],
            "rating": 4.6,
            "total_reviews": 567,
            "years_in_business": 10,
            "completed_projects": 5000,
            "trust_score": 96,
            "location": "Bangalore, Karnataka",
            "response_time": "< 6 hours"
        }
    }
    
    @classmethod
    def get_all_products(cls, category: Optional[str] = None) -> List[Dict]:
        """Get all products, optionally filtered by category"""
        if category:
            return cls.PRODUCTS.get(category, [])
        
        all_products = []
        for products in cls.PRODUCTS.values():
            all_products.extend(products)
        return all_products
    
    @classmethod
    def get_product(cls, product_id: str) -> Optional[Dict]:
        """Get a specific product by ID"""
        for products in cls.PRODUCTS.values():
            for product in products:
                if product['id'] == product_id:
                    # Add seller info
                    seller = cls.SELLERS.get(product['seller_id'])
                    product['seller'] = seller
                    return product
        return None
    
    @classmethod
    def get_seller(cls, seller_id: str) -> Optional[Dict]:
        """Get seller information"""
        return cls.SELLERS.get(seller_id)
    
    @classmethod
    def search_products(cls, query: str, category: Optional[str] = None) -> List[Dict]:
        """Search products by query"""
        products = cls.get_all_products(category)
        query_lower = query.lower()
        
        results = [
            p for p in products
            if query_lower in p['name'].lower() or
               query_lower in p.get('subcategory', '').lower()
        ]
        
        return results
    
    @classmethod
    def recommend_products(cls, user_profile: Dict) -> List[Dict]:
        """
        Smart product recommendations based on user profile
        
        Args:
            user_profile: {
                "action": "solar" | "energy_efficiency" | "sustainable",
                "budget": 50000,
                "location": "Mumbai"
            }
        """
        action = user_profile.get("action", "solar")
        budget = user_profile.get("budget", 100000)
        
        if action == "solar":
            products = cls.PRODUCTS["solar_equipment"]
        elif action == "energy_efficiency":
            products = cls.PRODUCTS["energy_efficient"]
        else:
            products = cls.PRODUCTS["sustainable_products"]
        
        # Filter by budget
        affordable = [p for p in products if p.get('price', 0) <= budget]
        
        # Sort by rating
        affordable.sort(key=lambda x: x.get('rating', 0), reverse=True)
        
        return affordable[:5]
    
    @classmethod
    def calculate_roi(cls, product_id: str, usage_hours_per_day: float = 8) -> Dict:
        """Calculate ROI for energy-efficient products"""
        product = cls.get_product(product_id)
        
        if not product or product['category'] != 'energy_efficient':
            return {"error": "Product not found or not energy-efficient"}
        
        savings_per_year = product.get('savings_per_year', 0)
        price = product.get('price', 0)
        
        if savings_per_year == 0:
            return {"error": "Savings data not available"}
        
        payback_months = (price / savings_per_year) * 12
        five_year_savings = (savings_per_year * 5) - price
        
        return {
            "product": product['name'],
            "upfront_cost": price,
            "annual_savings": savings_per_year,
            "payback_period_months": round(payback_months, 1),
            "five_year_profit": round(five_year_savings, 2),
            "roi_percentage": round((five_year_savings / price) * 100, 1)
        }
    
    @classmethod
    def get_verified_sellers(cls, category: Optional[str] = None) -> List[Dict]:
        """Get all verified sellers"""
        sellers = list(cls.SELLERS.values())
        
        if category:
            sellers = [s for s in sellers if s['category'] == category]
        
        # Sort by trust score
        sellers.sort(key=lambda x: x['trust_score'], reverse=True)
        
        return sellers
